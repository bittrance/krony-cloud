package main

import (
	"context"
	"encoding/json"
	"net/http"
	"time"

	"github.com/go-resty/resty/v2"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

type NullLogger struct{}

func (n *NullLogger) Errorf(format string, v ...interface{}) {}
func (n *NullLogger) Warnf(format string, v ...interface{})  {}
func (n *NullLogger) Debugf(format string, v ...interface{}) {}

var _ = Describe("WebhookReceiver", func() {
	var client *resty.Client
	var err error
	var response *resty.Response
	var server *http.Server

	BeforeEach(func() {
		server = RunReceiver("localhost:8080", false)

		client = resty.New()
		client.SetLogger(&NullLogger{})
		client.SetTimeout(time.Duration(50 * time.Millisecond))
		client.SetRetryCount(2)
	})

	JustAfterEach(func() {
		ctx, cancel := context.WithTimeout(context.Background(), 1*time.Second)
		defer cancel()
		server.Shutdown(ctx)
	})

	When("calling unknown entrypoint", func() {
		It("replies 404", func() {
			response, err = client.R().Get("http://localhost:8080/foo")
			Expect(err).To(BeNil())
			Expect(response.StatusCode()).To(Equal(404))
		})
	})

	When("logging entries", func() {
		It("replies ok", func() {
			response, err = client.R().Put("http://localhost:8080/log/foo")
			Expect(err).To(BeNil())
			Expect(response.StatusCode()).To(Equal(200))
			Expect(response.String()).To(Equal("ok"))
		})
	})

	When("looking at logged entries", func() {
		var seen map[string][]time.Time
		JustBeforeEach(func() {
			response, err = client.R().Get("http://localhost:8080/logs")
			Expect(err).To(BeNil())
			seen = make(map[string][]time.Time)
			json.Unmarshal(response.Body(), &seen)
		})

		It("starts empty", func() {
			Expect(seen).To(Equal(map[string][]time.Time{}))
		})

		Context("after some entries have been logged", func() {
			BeforeEach(func() {
				client.R().Put("http://localhost:8080/log/foo")
				client.R().Put("http://localhost:8080/log/foo")
				client.R().Put("http://localhost:8080/log/bar")
			})

			It("returns logged entries", func() {
				keys := make([]string, len(seen))
				for key := range seen {
					keys = append(keys, key)
				}
				Expect(keys).To(ContainElements("foo", "bar"))
			})
			It("notes the time of each call on an entry", func() {
				Expect(len(seen["foo"])).To(Equal(2))
			})

			Context("and the log has been cleared", func() {
				BeforeEach(func() {
					client.R().Delete("http://localhost:8080/logs")
				})

				It("is empty again", func() {
					Expect(seen).To(Equal(map[string][]time.Time{}))
				})
			})
		})
	})
})
