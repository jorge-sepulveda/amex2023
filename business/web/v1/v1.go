package v1

import (
	"net/http"
	"os"

	"github.com/ardanlabs/service/app/services/sales-api/v1/handlers/testgrp"
	"github.com/ardanlabs/service/business/web/v1/mid"
	"github.com/ardanlabs/service/foundation/logger"
	"github.com/ardanlabs/service/foundation/web"
)

// APIMuxConfig contains all the mandatory systems required by handlers.
type APIMuxConfig struct {
	Build    string
	Shutdown chan os.Signal
	Log      *logger.Logger
}

func APIMux(cfg APIMuxConfig) *web.App {
	app := web.NewApp(cfg.Shutdown, mid.Logger(cfg.Log), mid.Error(cfg.Log))

	app.Handle(http.MethodGet, "/test", testgrp.Test)

	return app
}
