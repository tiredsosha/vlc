package main

import (
	"errors"
	"fmt"
	"io"
	"net/http"
	"os"
	"os/exec"
)

func getRoot(w http.ResponseWriter, r *http.Request) {
	fmt.Printf("got / request\n")
	out, err := exec.Command("bash", "-c", "sudo systemctl restart vlc.service").Output()
	fmt.Println(out)
	fmt.Println(err)
	io.WriteString(w, "This is my website!\n")
}

func main() {
	http.HandleFunc("/", getRoot)

	err := http.ListenAndServe(":8000", nil)
	if errors.Is(err, http.ErrServerClosed) {
		fmt.Printf("server closed\n")
	} else if err != nil {
		fmt.Printf("error starting server: %s\n", err)
		os.Exit(1)
	}
}
