package main

import (
	"encoding/binary"
	"fmt"
	"io"
	"log"
	"net"

	"golang.org/x/sync/errgroup"
)

func writeString(conn io.Writer, str string) error {
	data := []byte(str)

	buf := make([]byte, 4)

	binary.LittleEndian.PutUint32(buf, uint32(len(data)))
	if _, err := conn.Write(buf); err != nil {
		return err
	}

	if _, err := conn.Write(data); err != nil {
		return err
	}

	return nil
}

func readString(conn io.Reader) (string, error) {
	buf := make([]byte, 4)
	if _, err := io.ReadFull(conn, buf); err != nil {
		return "", err
	}

	len := int(binary.LittleEndian.Uint32(buf))

	buf = make([]byte, len)
	if _, err := io.ReadFull(conn, buf); err != nil {
		return "", err
	}

	return string(buf), nil
}

func server() {
	l, err := net.Listen("tcp", "localhost:8001")
	if err != nil {
		log.Fatal(err)
	}
	defer l.Close()

	conn, err := l.Accept()
	if err != nil {
		log.Fatal(err)
	}
	defer conn.Close()

	str, err := readString(conn)
	if err != nil {
		log.Fatal(err)
	}

	if err := writeString(conn, "Re: "+str); err != nil {
		log.Fatal(err)
	}

	fmt.Println(str)

	str, err = readString(conn)
	if err != nil {
		log.Fatal(err)
	}

	fmt.Println(str)
}

func client() {
	conn, err := net.Dial("tcp", "localhost:8001")
	if err != nil {
		log.Fatal(err)
	}
	defer conn.Close()

	if err := writeString(conn, "hogehoge"); err != nil {
		log.Fatal(err)
	}

	if err := writeString(conn, "piyopiyo"); err != nil {
		log.Fatal(err)
	}

	str, err := readString(conn)
	if err != nil {
		log.Fatal(err)
	}

	fmt.Println(str)
}

func main() {
	var eg errgroup.Group

	eg.Go(func() error {
		server()
		return nil
	})
	eg.Go(func() error {
		client()
		return nil
	})

	eg.Wait()
}
