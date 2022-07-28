package main

import (
	"errors"
	"fmt"
	"io"
	"net/http"
	"os"
	"os/exec"
	"time"
)

func getRoot(w http.ResponseWriter, r *http.Request) {
	fmt.Printf("got / request\n")
	out2, err2 := exec.Command("bash", "-c", "pkill -f vlc").Output()
	fmt.Println(out2)
	fmt.Println(err2)
	time.Sleep(20 * time.Second)
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
