ARG GO_VERSION=1.23.6
ARG BASE_IMAGE=djkazic/lnd
ARG BASE_IMAGE_VERSION=v0.19.0-beta.rc4-super-prio
ARG BASE_IMAGE_HASH=sha256:5a9019c39d864a87f0ff35a1da9f2c8da7a2e9920fd883dad2210c6955a28118

FROM golang:${GO_VERSION}-alpine as builder

# Force Go to use the cgo based DNS resolver. This is required to ensure DNS
# queries required to connect to linked containers succeed.
ENV GODEBUG netdns=cgo

# Pass a tag, branch or a commit using build-arg. This allows a docker image to
# be built from a specified Git state. The default image will use the Git tip of
# main by default.
ARG checkout="super-prio"
ARG git_url="https://github.com/djkazic/lndinit"

# Install dependencies and build the binaries.
RUN apk add --no-cache --update alpine-sdk \
  git \
  make \
  &&  git clone $git_url /go/src/github.com/lightninglabs/lndinit \
  &&  cd /go/src/github.com/lightninglabs/lndinit \
  &&  git checkout $checkout \
  &&  make release-install

# Start a new, final image.
FROM ${BASE_IMAGE}:${BASE_IMAGE_VERSION}@${BASE_IMAGE_HASH} as final

# Copy the binary from the builder image.
COPY --from=builder /go/bin/lndinit /bin/
