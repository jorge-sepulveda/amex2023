package testgrp

import (
	"context"
	"errors"
	"math/rand"
	"net/http"

	"github.com/ardanlabs/service/business/web/v1/trusted"
	"github.com/ardanlabs/service/foundation/web"
)

func Test(ctx context.Context, w http.ResponseWriter, r *http.Request) error {
	if n := rand.Intn(100); n%2 == 0 {
		return trusted.NewError(errors.New("TRUSTED ERROR"), http.StatusBadRequest)
	}

	status := struct {
		Status string
	}{
		Status: "OK",
	}

	return web.Respond(ctx, w, status, http.StatusOK)
}
