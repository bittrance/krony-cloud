package main_test

import (
	"testing"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

func TestWebhookReceiver(t *testing.T) {
	RegisterFailHandler(Fail)
	RunSpecs(t, "WebhookReceiver Suite")
}
