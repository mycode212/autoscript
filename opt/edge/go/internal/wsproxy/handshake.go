package wsproxy

import (
	"bufio"
	"crypto/sha1"
	"encoding/base64"
	"errors"
	"fmt"
	"net"
	"os"
	"strings"
	"time"
)

const websocketGUID = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"

type HandshakeError struct {
	Code   int
	Reason string
}

func (e *HandshakeError) Error() string { return e.Reason }

func PathAllowed(requestPath, expectedPath string) bool {
	pathOnly := strings.SplitN(strings.SplitN(requestPath, "?", 2)[0], "#", 2)[0]
	expectedOnly := strings.SplitN(strings.SplitN(expectedPath, "?", 2)[0], "#", 2)[0]
	if pathOnly == "" {
		pathOnly = "/"
	}
	if expectedOnly == "" {
		expectedOnly = "/"
	}
	if expectedOnly == "/" {
		return strings.HasPrefix(pathOnly, "/")
	}
	return pathOnly == expectedOnly || strings.HasPrefix(pathOnly, expectedOnly+"/")
}

func ReadHandshake(reader *bufio.Reader, conn net.Conn, timeout time.Duration, expectedPath string) (map[string]string, string, string, error) {
	_ = conn.SetReadDeadline(time.Now().Add(timeout))
	defer conn.SetReadDeadline(time.Time{})
	if reader == nil {
		reader = bufio.NewReader(conn)
	}

	for {
		line, err := reader.ReadString('\n')
		if err != nil {
			if errors.Is(err, os.ErrDeadlineExceeded) {
				return nil, "", "", &HandshakeError{Code: 408, Reason: "Request Timeout"}
			}
			return nil, "", "", &HandshakeError{Code: 400, Reason: "Bad Request"}
		}
		trimmed := strings.TrimSpace(line)
		if trimmed == "" {
			continue
		}
		req := strings.Fields(trimmed)
		if len(req) < 3 {
			continue
		}
		target := req[1]
		path := target
		if strings.Contains(target, "://") {
			if u, err := netURLSplit(target); err == nil {
				path = u
			}
		}

		headers := map[string]string{}
		for {
			headerLine, err := reader.ReadString('\n')
			if err != nil {
				return nil, "", "", &HandshakeError{Code: 400, Reason: "Bad Request"}
			}
			headerLine = strings.TrimRight(headerLine, "\r\n")
			if headerLine == "" {
				break
			}
			k, v, ok := strings.Cut(headerLine, ":")
			if !ok {
				continue
			}
			headers[strings.ToLower(strings.TrimSpace(k))] = strings.TrimSpace(v)
		}

		// Jika request ini bukan upgrade websocket (misal probe split payload awal), lanjutkan baca request berikutnya
		if strings.ToLower(headers["upgrade"]) != "websocket" {
			continue
		}

		if !PathAllowed(path, expectedPath) {
			return nil, "", "", &HandshakeError{Code: 404, Reason: "Not Found"}
		}

		key := headers["sec-websocket-key"]
		if strings.TrimSpace(key) == "" {
			// Default to a dummy key so HTTP Injector / custom payloads without it still work
			key = "dGhlIHNhbXBsZSBub25jZQ=="
		}
		return headers, path, websocketAccept(key), nil
	}
}

func SendHTTPError(conn net.Conn, code int, reason string) {
	body := []byte(fmt.Sprintf("%d %s\n", code, reason))
	resp := fmt.Sprintf("HTTP/1.1 %d %s\r\nContent-Type: text/plain\r\nContent-Length: %d\r\nConnection: close\r\n\r\n", code, reason, len(body))
	_, _ = conn.Write(append([]byte(resp), body...))
}

func SendHandshakeOK(conn net.Conn, accept string) error {
	resp := "HTTP/1.1 101 Switching Protocols\r\n" +
		"Upgrade: websocket\r\n" +
		"Connection: Upgrade\r\n" +
		"Sec-WebSocket-Accept: " + accept + "\r\n\r\n"
	_, err := conn.Write([]byte(resp))
	return err
}

func firstForwardedIP(value string) string {
	for _, item := range strings.Split(value, ",") {
		if ip := NormalizeIP(item); ip != "" {
			return ip
		}
	}
	return ""
}

func ExtractClientIP(headers map[string]string, conn net.Conn) string {
	if ip := NormalizeIP(headers["cf-connecting-ip"]); ip != "" {
		return ip
	}
	if ip := NormalizeIP(headers["x-real-ip"]); ip != "" {
		return ip
	}
	if ip := firstForwardedIP(headers["x-forwarded-for"]); ip != "" {
		return ip
	}
	if addr, ok := conn.RemoteAddr().(*net.TCPAddr); ok && addr.IP != nil {
		if ip := NormalizeIP(addr.IP.String()); ip != "" {
			return ip
		}
	}
	host, _, err := net.SplitHostPort(conn.RemoteAddr().String())
	if err == nil {
		return NormalizeIP(host)
	}
	return ""
}

func websocketAccept(key string) string {
	sum := sha1.Sum([]byte(strings.TrimSpace(key) + websocketGUID))
	return base64.StdEncoding.EncodeToString(sum[:])
}

func netURLSplit(target string) (string, error) {
	i := strings.Index(target, "://")
	if i < 0 {
		return target, nil
	}
	rest := target[i+3:]
	slash := strings.IndexByte(rest, '/')
	if slash < 0 {
		return "/", nil
	}
	return rest[slash:], nil
}
