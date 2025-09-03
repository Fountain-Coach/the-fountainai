# Developer Documentation

This directory collects generated documentation derived from inline `///` comments.
As modules gain documentation, brief summaries are added here.

## Current Highlights
- **PublishingFrontend** – lightweight static HTTP server for serving the `/Public` directory.
- **HTTPKernel** – simple asynchronous router used by the gateway and publishing frontend.
- **DNSProvider** – abstraction over DNS APIs.
- **AsyncHTTPClientDriver** and **URLSessionHTTPClient** – documented HTTP clients powering network requests. The former now includes top-level class docs and dedicated tests verifying request execution.
- **AsyncHTTPClientDriver.execute** – documents the returned response buffer, headers, and network error propagation.
- **NIOHTTPServer** – documented server adapter built on SwiftNIO.
- **NIOHTTPServer.kernel**, **group**, and **channel** – internal server properties now described.
- **HTTPHandler** – internal request dispatcher within `NIOHTTPServer` is now thoroughly documented.
- **NIOHTTPServer.init** – initializer now documents kernel and event loop group parameters.
- **LoggingPlugin** – prints requests and responses for debugging.
- **LoggingPlugin.prepare** and **respond** – inline comments explain logging without mutating headers or bodies.
- **GatewayPlugin** – protocol for request and response middleware.
- **GatewayPlugin.prepare** and **respond** – default implementations now explain parameters and return values.
- **CertificateManager** – runs periodic certificate renewal scripts.
- **SpecLoader** – parses OpenAPI specifications from JSON or YAML.
- **ClientGenerator** and **ServerGenerator** – emit Swift client and server code from specs.
- **GeneratorCLI** – command line interface for the code generators.
- **HTTPRequest** and **HTTPResponse** – request/response models now fully documented.
- **NoBody** – placeholder type for empty request bodies is now documented.
- **APIRequest** – protocol now documents HTTP method, path, and body fields.
- **APIClient** – initializer and URLSession extension now documented for clarity.
- **URLSessionHTTPClientTests** – updated for Linux compatibility ensuring network client coverage.
- **OpenAPISpec.swiftType** – documented helper converting schemas to Swift types.
- **String.camelCased** – extension for transforming snake case identifiers; now documents that leading, trailing, and consecutive underscores are ignored and numeric segments are preserved, with comments explaining underscore splitting and recombination logic for clarity.
- **FountainAiLauncher CLI** – supervisor entrypoint launching configured services; requires `FOUNTAINSTORE_URL` and `FOUNTAINSTORE_API_KEY`.
- **publishing-frontend CLI** – documented main entrypoint starting the static server.
- **clientgen-service CLI** – wrapper around GeneratorCLI is now documented.
- **gateway-server CLI** – documented gateway server entrypoint exposing the HTTP gateway.
- **GatewayServerTests** – verifies the gateway's health endpoint.
- **GatewayServer** – documentation now covers health and metrics endpoints.
- **Service** and **Supervisor** – properties and lifecycle methods documented.
- **SpecValidator** – checks OpenAPI documents for duplicate IDs and unresolved references.
- **SpecValidator.validateSchema** – documents recursive schema reference checks and path placeholder enforcement.
- **PublishingConfig.port** and **rootPath** – documented properties clarifying server binding and static directory.
- **Todo.id** and **Todo.name** – documented properties clarifying task identifiers and titles.
- **OpenAPISpec** – root model now documents components, servers, security schemes, and requirements.
- **openapi Todo** – generated model now documents its properties.
- **GatewayServer** – internal components like the certificate manager and plugin stack are now described.
- **GatewayServer.start** and **stop** – documentation now explains certificate manager activation and graceful shutdown.
- **APIClient.baseURL**, **session**, and **defaultHeaders** – stored properties document connection details.
- **ServerGenerator emit helpers** – private functions now describe generated source responsibilities.
- **PublishingFrontendPlugin.rootPath** – documented property describing the static file directory.
- **PublishingFrontend.server**, **group**, and **config** – internal properties now describe server instance, event loop management, and runtime configuration.
- **CertificateManager.start**, **stop**, and **triggerNow** – document timer scheduling, cancellation semantics, and on-demand execution.
- **HTTPRequest.method**, **path**, **headers**, and **body** – properties now describe their respective roles.
- **HTTPResponse.status**, **headers**, and **body** – properties now clarify response components.
- **HTTPKernel.handle** – now documents error propagation from routing closures.
- **run-tests.sh** – helper script bundling release build and coverage test steps with inline comments explaining log generation.
- **PublishingFrontendPlugin.respond** – documents parameters and emitted `Content-Type` header when serving files.
- **GatewayServer.plugins** – documents plugin execution order for request preparation and response processing.
- **GatewayServer.init** – clarifies plugin invocation order for preparation and response phases.
- **SpecLoader.load** – documents removal of copyright lines before decoding.
- **SpecLoader.load** – clarifies JSON fallback and error reporting for invalid input data.
- **OpenAPISpec.Parameter.swiftName** and **swiftType** – document parameter name sanitization and schema type defaults.
- **OpenAPISpec.Parameter.name**, **location**, **required**, and **schema** – properties now clarify identifiers, where parameters appear, necessity, and data typing.
- **OpenAPISpec.Schema.Property.swiftType** – inline comments clarify array and object mappings and default behavior.
- **services array** – startup service list in `FountainAiLauncher` now documented.
- **ClientGenerator.emitRequest** – documents generation of request types handling path and query parameters.
- **renew-certs.sh** – script obtaining TLS certificates via `certbot` using DNS-01 challenge and API hooks with configurable environment variables.
- **loadPublishingConfig** – documents error handling for missing files, invalid YAML, and defaulting of absent keys.
- **APIClient.send** – documents special handling for `Data` and `NoBody` responses.
- **SimpleHTTPRuntime** – low-level planner runtime now documents its connection acceptance, request parsing, and response serialization flow.
- **Planner v0 specification** – now aliases to v1, formally deprecating the older version.

Documentation coverage will expand alongside test coverage.

---
© 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
