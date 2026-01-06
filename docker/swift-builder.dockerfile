ARG SWIFT_VERSION=6.2
FROM swift:${SWIFT_VERSION}-jammy

# Add user for building, customizable
ARG USER=build-user
ARG UID=1000
RUN useradd -m -r -u ${UID} ${USER}
