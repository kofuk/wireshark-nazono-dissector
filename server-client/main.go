package main

import (
	"encoding/binary"
	"fmt"
	"io"
	"log"
	"net"

	"golang.org/x/sync/errgroup"
)

func writeString(conn io.Writer, str string, key byte) error {
	data := []byte(str)

	buf := make([]byte, 4)

	binary.LittleEndian.PutUint32(buf, uint32(len(data)))
	for i, b := range buf {
		buf[i] = b ^ key
	}
	if _, err := conn.Write(buf); err != nil {
		return err
	}

	for i, b := range data {
		data[i] = b ^ key
	}
	if _, err := conn.Write(data); err != nil {
		return err
	}

	return nil
}

func readString(conn io.Reader, key byte) (string, error) {
	buf := make([]byte, 4)
	if _, err := io.ReadFull(conn, buf); err != nil {
		return "", err
	}
	for i, b := range buf {
		buf[i] = b ^ key
	}

	len := int(binary.LittleEndian.Uint32(buf))

	buf = make([]byte, len)
	if _, err := io.ReadFull(conn, buf); err != nil {
		return "", err
	}
	for i, b := range buf {
		buf[i] = b ^ key
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

	buf := make([]byte, 6)
	if _, err := io.ReadFull(conn, buf); err != nil {
		log.Fatal(err)
	}

	key := buf[5]

	str, err := readString(conn, key)
	if err != nil {
		log.Fatal(err)
	}

	if err := writeString(conn, "Re: "+str, key); err != nil {
		log.Fatal(err)
	}

	fmt.Println(str)

	str, err = readString(conn, key)
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

	if _, err := conn.Write([]byte("HELLOa")); err != nil {
		log.Fatal(err)
	}

	key := byte('a')

	if err := writeString(conn, "hogehoge", key); err != nil {
		log.Fatal(err)
	}

	if err := writeString(conn, "piyopiyo", key); err != nil {
		log.Fatal(err)
	}

	str, err := readString(conn, key)
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
