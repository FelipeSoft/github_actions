package main

import (
	"log"
	"net/http"
	"sync"
)

func main() {
	var wg sync.WaitGroup

	server := http.NewServeMux()
	server.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		if r.Method != "GET" {
			w.WriteHeader(http.StatusMethodNotAllowed)
			return
		}
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("Hello World!"))
	})

	wg.Add(1)
	go func() {
		defer wg.Done()
		log.Print("HTTP server listening on 127.0.0.1:3031")
		if err := http.ListenAndServe("127.0.0.1:3031", server); err != nil {
			log.Fatalf("Error during the HTTP server listening: %v", err)
		}
	}()

	wg.Wait()
}
