package testgrp

import (
	"net/http"

	"github.com/ardanlabs/service/business/web/v1/auth"
	"github.com/ardanlabs/service/business/web/v1/mid"
	"github.com/ardanlabs/service/foundation/web"
)

// Config contains all the mandatory systems required by handlers.
type Config struct {
	Auth *auth.Auth
}

// Routes adds specific routes for this group.
func Routes(app *web.App, cfg Config) {
	rule := "ruleUserOnly"

	app.Handle(http.MethodGet, "/test", Test)
	app.Handle(http.MethodGet, "/auth", Test, mid.Authenticate(cfg.Auth), mid.Authorize(cfg.Auth, rule))

}
