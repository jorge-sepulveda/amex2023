package v1

import (
	"encoding/json"
	"net/http"
	"os"

	"github.com/ardanlabs/service/foundation/logger"
	"github.com/dimfeld/httptreemux/v5"
)

// APIMuxConfig contains all the mandatory systems required by handlers.
type APIMuxConfig struct {
	Build    string
	Shutdown chan os.Signal
	Log      *logger.Logger
}

func APIMux(cfg APIMuxConfig) *httptreemux.ContextMux {
	mux := httptreemux.NewContextMux()

	h := func(w http.ResponseWriter, r *http.Request) {
		status := struct {
			Status string
		}{
			Status: "OK",
		}
		json.NewEncoder(w).Encode(status)
	}

	mux.Handle(http.MethodGet, "/test", h)

	return mux
}
