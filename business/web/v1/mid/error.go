package mid

import (
	"context"
	"net/http"

	"github.com/ardanlabs/service/business/web/v1/trusted"
	"github.com/ardanlabs/service/foundation/logger"
	"github.com/ardanlabs/service/foundation/web"
)

func Error(log *logger.Logger) web.Middleware {
	m := func(handler web.Handler) web.Handler {
		h := func(ctx context.Context, w http.ResponseWriter, r *http.Request) error {
			if err := handler(ctx, w, r); err != nil {
				log.Error(ctx, "message", "msg", err)

				var er trusted.ErrorDocument
				var status int

				switch {
				case trusted.IsError(err):
					trsErr := trusted.GetError(err)

					er = trusted.ErrorDocument{
						Error: trsErr.Error(),
					}
					status = trsErr.Status

				default:
					er = trusted.ErrorDocument{
						Error: http.StatusText(http.StatusInternalServerError),
					}
					status = http.StatusInternalServerError
				}

				if err := web.Respond(ctx, w, er, status); err != nil {
					return err
				}

				// If we receive the shutdown err we need to return it
				// back to the base handler to shut down the service.
				if web.IsShutdown(err) {
					return err
				}
			}

			return nil
		}

		return h
	}

	return m
}
