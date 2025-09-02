import Foundation

public struct Handlers {
    let service: TypesenseService

    public init(service: TypesenseService = try! TypesenseService()) {
        self.service = service
    }
    public func getsearchoverrides(_ request: HTTPRequest, body: NoBody?) async throws -> HTTPResponse {
        let parts = request.path.split(separator: "/")
        guard parts.count >= 3 else { return HTTPResponse(status: 404) }
        let collection = String(parts[1])
        let overrides = try await service.getSearchOverrides(collection: collection)
        let data = try JSONEncoder().encode(overrides)
        return HTTPResponse(status: 200, headers: ["Content-Type": "application/json"], body: data)
    }
    public func exportdocuments(_ request: HTTPRequest, body: NoBody?) async throws -> HTTPResponse {
        let parts = request.path.split(separator: "/")
        guard parts.count >= 4 else { return HTTPResponse(status: 404) }
        let collection = String(parts[1])
        let comps = URLComponents(string: request.path)
        var params: [String: String] = [:]
        for item in comps?.queryItems ?? [] {
            if let value = item.value { params[item.name] = value }
        }
        let data = try await service.exportDocuments(collection: collection, parameters: params.isEmpty ? nil : params)
        return HTTPResponse(status: 200, headers: ["Content-Type": "application/octet-stream"], body: data)
    }
    public func indexdocument(_ request: HTTPRequest, body: indexDocumentRequest?) async throws -> HTTPResponse {
        guard let doc = body else { return HTTPResponse(status: 400) }
        let parts = request.path.split(separator: "/")
        guard parts.count >= 3 else { return HTTPResponse(status: 404) }
        let collection = String(parts[1])
        let comps = URLComponents(string: request.path)
        var action: IndexAction?
        var dirty: DirtyValues?
        for item in comps?.queryItems ?? [] {
            if item.name == "action", let value = item.value { action = IndexAction(rawValue: value) }
            if item.name == "dirty_values", let value = item.value { dirty = DirtyValues(rawValue: value) }
        }
        let data = try await service.indexDocument(collection: collection, document: doc, action: action, dirtyValues: dirty)
        return HTTPResponse(status: 201, headers: ["Content-Type": "application/json"], body: data)
    }
    public func updatedocuments(_ request: HTTPRequest, body: updateDocumentsRequest?) async throws -> HTTPResponse {
        guard let fields = body else { return HTTPResponse(status: 400) }
        let parts = request.path.split(separator: "/")
        guard parts.count >= 3 else { return HTTPResponse(status: 404) }
        let collection = String(parts[1])
        let comps = URLComponents(string: request.path)
        var params: [String: String] = [:]
        for item in comps?.queryItems ?? [] { if let value = item.value { params[item.name] = value } }
        let result = try await service.updateDocuments(collection: collection, document: fields, parameters: params.isEmpty ? nil : params)
        let data = try JSONEncoder().encode(result)
        return HTTPResponse(status: 200, headers: ["Content-Type": "application/json"], body: data)
    }
    public func deletedocuments(_ request: HTTPRequest, body: NoBody?) async throws -> HTTPResponse {
        let parts = request.path.split(separator: "/")
        guard parts.count >= 3 else { return HTTPResponse(status: 404) }
        let collection = String(parts[1])
        let comps = URLComponents(string: request.path)
        var params: [String: String] = [:]
        for item in comps?.queryItems ?? [] { if let value = item.value { params[item.name] = value } }
        let result = try await service.deleteDocuments(collection: collection, parameters: params.isEmpty ? nil : params)
        let data = try JSONEncoder().encode(result)
        return HTTPResponse(status: 200, headers: ["Content-Type": "application/json"], body: data)
    }
    public func createanalyticsevent(_ request: HTTPRequest, body: AnalyticsEventCreateSchema?) async throws -> HTTPResponse {
        guard let schema = body else { return HTTPResponse(status: 400) }
        let data = try await service.createAnalyticsEvent(schema: schema)
        return HTTPResponse(status: 201, headers: ["Content-Type": "application/json"], body: data)
    }
    public func retrieveanalyticsrule(_ request: HTTPRequest, body: NoBody?) async throws -> HTTPResponse {
        let parts = request.path.split(separator: "/")
        guard parts.count >= 3 else { return HTTPResponse(status: 404) }
        let name = String(parts[2])
        let rule = try await service.retrieveAnalyticsRule(name: name)
        let data = try JSONEncoder().encode(rule)
        return HTTPResponse(status: 200, headers: ["Content-Type": "application/json"], body: data)
    }
    public func upsertanalyticsrule(_ request: HTTPRequest, body: AnalyticsRuleUpsertSchema?) async throws -> HTTPResponse {
        guard let schema = body else { return HTTPResponse(status: 400) }
        let parts = request.path.split(separator: "/")
        guard parts.count >= 3 else { return HTTPResponse(status: 404) }
        let name = String(parts[2])
        let rule = try await service.upsertAnalyticsRule(name: name, schema: schema)
        let data = try JSONEncoder().encode(rule)
        return HTTPResponse(status: 200, headers: ["Content-Type": "application/json"], body: data)
    }
    public func deleteanalyticsrule(_ request: HTTPRequest, body: NoBody?) async throws -> HTTPResponse {
        let parts = request.path.split(separator: "/")
        guard parts.count >= 3 else { return HTTPResponse(status: 404) }
        let name = String(parts[2])
        let result = try await service.deleteAnalyticsRule(name: name)
        let data = try JSONEncoder().encode(result)
        return HTTPResponse(status: 200, headers: ["Content-Type": "application/json"], body: data)
    }
    public func liststemmingdictionaries(_ request: HTTPRequest, body: NoBody?) async throws -> HTTPResponse {
        let list = try await service.listStemmingDictionaries()
        let data = try JSONEncoder().encode(list)
        return HTTPResponse(status: 200, headers: ["Content-Type": "application/json"], body: data)
    }
    public func getcollections(_ request: HTTPRequest, body: NoBody?) async throws -> HTTPResponse {
        let collections = try await service.listCollections()
        let data = try JSONEncoder().encode(collections)
        return HTTPResponse(status: 200, headers: ["Content-Type": "application/json"], body: data)
    }
    public func createcollection(_ request: HTTPRequest, body: CollectionSchema?) async throws -> HTTPResponse {
        guard let schema = body else { return HTTPResponse(status: 400) }
        let data = try await service.createCollection(schema: schema)
        return HTTPResponse(status: 200, headers: ["Content-Type": "application/json"], body: data)
    }
    public func retrieveallconversationmodels(_ request: HTTPRequest, body: NoBody?) async throws -> HTTPResponse {
        let models = try await service.retrieveAllConversationModels()
        let data = try JSONEncoder().encode(models)
        return HTTPResponse(status: 200, headers: ["Content-Type": "application/json"], body: data)
    }
    public func createconversationmodel(_ request: HTTPRequest, body: ConversationModelCreateSchema?) async throws -> HTTPResponse {
        guard let schema = body else { return HTTPResponse(status: 400) }
        let model = try await service.createConversationModel(schema: schema)
        let data = try JSONEncoder().encode(model)
        return HTTPResponse(status: 200, headers: ["Content-Type": "application/json"], body: data)
    }
    public func getcollection(_ request: HTTPRequest, body: NoBody?) async throws -> HTTPResponse {
        let parts = request.path.split(separator: "/")
        guard parts.count >= 2 else { return HTTPResponse(status: 404) }
        let name = String(parts[1])
        let collection = try await service.getCollection(name: name)
        let data = try JSONEncoder().encode(collection)
        return HTTPResponse(status: 200, headers: ["Content-Type": "application/json"], body: data)
    }
    public func updatecollection(_ request: HTTPRequest, body: CollectionUpdateSchema?) async throws -> HTTPResponse {
        guard let schema = body else { return HTTPResponse(status: 400) }
        let parts = request.path.split(separator: "/")
        guard parts.count >= 2 else { return HTTPResponse(status: 404) }
        let name = String(parts[1])
        let updated = try await service.updateCollection(name: name, schema: schema)
        let data = try JSONEncoder().encode(updated)
        return HTTPResponse(status: 200, headers: ["Content-Type": "application/json"], body: data)
    }
    public func deletecollection(_ request: HTTPRequest, body: NoBody?) async throws -> HTTPResponse {
        let parts = request.path.split(separator: "/")
        guard parts.count >= 2 else { return HTTPResponse(status: 404) }
        let name = String(parts[1])
        let collection = try await service.deleteCollection(name: name)
        let data = try JSONEncoder().encode(collection)
        return HTTPResponse(status: 200, headers: ["Content-Type": "application/json"], body: data)
    }
    public func getkeys(_ request: HTTPRequest, body: NoBody?) async throws -> HTTPResponse {
        let keys = try await service.getKeys()
        let data = try JSONEncoder().encode(keys)
        return HTTPResponse(status: 200, headers: ["Content-Type": "application/json"], body: data)
    }
    public func createkey(_ request: HTTPRequest, body: ApiKeySchema?) async throws -> HTTPResponse {
        guard let schema = body else { return HTTPResponse(status: 400) }
        let data = try await service.createKey(schema: schema)
        return HTTPResponse(status: 200, headers: ["Content-Type": "application/json"], body: data)
    }
    public func vote(_ request: HTTPRequest, body: NoBody?) async throws -> HTTPResponse {
        let status = try await service.vote()
        let data = try JSONEncoder().encode(status)
        return HTTPResponse(status: 200, headers: ["Content-Type": "application/json"], body: data)
    }
    public func retrieveanalyticsrules(_ request: HTTPRequest, body: NoBody?) async throws -> HTTPResponse {
        let rules = try await service.retrieveAnalyticsRules()
        let data = try JSONEncoder().encode(rules)
        return HTTPResponse(status: 200, headers: ["Content-Type": "application/json"], body: data)
    }
    public func createanalyticsrule(_ request: HTTPRequest, body: AnalyticsRuleSchema?) async throws -> HTTPResponse {
        guard let schema = body else { return HTTPResponse(status: 400) }
        let data = try await service.createAnalyticsRule(schema: schema)
        return HTTPResponse(status: 201, headers: ["Content-Type": "application/json"], body: data)
    }
    public func getalias(_ request: HTTPRequest, body: NoBody?) async throws -> HTTPResponse {
        let parts = request.path.split(separator: "/")
        guard parts.count >= 2 else { return HTTPResponse(status: 404) }
        let name = String(parts[1])
        let alias = try await service.getAlias(name: name)
        let data = try JSONEncoder().encode(alias)
        return HTTPResponse(status: 200, headers: ["Content-Type": "application/json"], body: data)
    }
    public func upsertalias(_ request: HTTPRequest, body: CollectionAliasSchema?) async throws -> HTTPResponse {
        guard let schema = body else { return HTTPResponse(status: 400) }
        let parts = request.path.split(separator: "/")
        guard parts.count >= 2 else { return HTTPResponse(status: 404) }
        let name = String(parts[1])
        let alias = try await service.upsertAlias(name: name, schema: schema)
        let data = try JSONEncoder().encode(alias)
        return HTTPResponse(status: 200, headers: ["Content-Type": "application/json"], body: data)
    }
    public func deletealias(_ request: HTTPRequest, body: NoBody?) async throws -> HTTPResponse {
        let parts = request.path.split(separator: "/")
        guard parts.count >= 2 else { return HTTPResponse(status: 404) }
        let name = String(parts[1])
        let alias = try await service.deleteAlias(name: name)
        let data = try JSONEncoder().encode(alias)
        return HTTPResponse(status: 200, headers: ["Content-Type": "application/json"], body: data)
    }
    public func retrieveconversationmodel(_ request: HTTPRequest, body: NoBody?) async throws -> HTTPResponse {
        let parts = request.path.split(separator: "/")
        guard parts.count >= 3 else { return HTTPResponse(status: 404) }
        let id = String(parts[2])
        let model = try await service.retrieveConversationModel(id: id)
        let data = try JSONEncoder().encode(model)
        return HTTPResponse(status: 200, headers: ["Content-Type": "application/json"], body: data)
    }
    public func updateconversationmodel(_ request: HTTPRequest, body: ConversationModelUpdateSchema?) async throws -> HTTPResponse {
        guard let schema = body else { return HTTPResponse(status: 400) }
        let parts = request.path.split(separator: "/")
        guard parts.count >= 3 else { return HTTPResponse(status: 404) }
        let id = String(parts[2])
        let model = try await service.updateConversationModel(id: id, schema: schema)
        let data = try JSONEncoder().encode(model)
        return HTTPResponse(status: 200, headers: ["Content-Type": "application/json"], body: data)
    }
    public func deleteconversationmodel(_ request: HTTPRequest, body: NoBody?) async throws -> HTTPResponse {
        let parts = request.path.split(separator: "/")
        guard parts.count >= 3 else { return HTTPResponse(status: 404) }
        let id = String(parts[2])
        let model = try await service.deleteConversationModel(id: id)
        let data = try JSONEncoder().encode(model)
        return HTTPResponse(status: 200, headers: ["Content-Type": "application/json"], body: data)
    }
    public func takesnapshot(_ request: HTTPRequest, body: NoBody?) async throws -> HTTPResponse {
        let comps = URLComponents(string: request.path)
        guard let path = comps?.queryItems?.first(where: { $0.name == "snapshot_path" })?.value else {
            return HTTPResponse(status: 400)
        }
        let data = try await service.takeSnapshot(path: path)
        return HTTPResponse(status: 201, headers: ["Content-Type": "application/json"], body: data)
    }
    public func multisearch(_ request: HTTPRequest, body: MultiSearchSearchesParameter?) async throws -> HTTPResponse {
        guard let searches = body else { return HTTPResponse(status: 400) }
        let comps = URLComponents(string: request.path)
        let params = comps?.queryItems?.first(where: { $0.name == "multiSearchParameters" })?.value ?? "{}"
        let result = try await service.multiSearch(parameters: params, body: searches)
        let data = try JSONEncoder().encode(result)
        return HTTPResponse(status: 200, headers: ["Content-Type": "application/json"], body: data)
    }
    public func retrievenlsearchmodel(_ request: HTTPRequest, body: NoBody?) async throws -> HTTPResponse {
        let parts = request.path.split(separator: "/")
        guard parts.count >= 3 else { return HTTPResponse(status: 404) }
        let id = String(parts[2])
        let model = try await service.retrieveNLSearchModel(id: id)
        let data = try JSONEncoder().encode(model)
        return HTTPResponse(status: 200, headers: ["Content-Type": "application/json"], body: data)
    }
    public func updatenlsearchmodel(_ request: HTTPRequest, body: NLSearchModelUpdateSchema?) async throws -> HTTPResponse {
        guard let schema = body else { return HTTPResponse(status: 400) }
        let parts = request.path.split(separator: "/")
        guard parts.count >= 3 else { return HTTPResponse(status: 404) }
        let id = String(parts[2])
        let model = try await service.updateNLSearchModel(id: id, schema: schema)
        let data = try JSONEncoder().encode(model)
        return HTTPResponse(status: 200, headers: ["Content-Type": "application/json"], body: data)
    }
    public func deletenlsearchmodel(_ request: HTTPRequest, body: NoBody?) async throws -> HTTPResponse {
        let parts = request.path.split(separator: "/")
        guard parts.count >= 3 else { return HTTPResponse(status: 404) }
        let id = String(parts[2])
        let result = try await service.deleteNLSearchModel(id: id)
        let data = try JSONEncoder().encode(result)
        return HTTPResponse(status: 200, headers: ["Content-Type": "application/json"], body: data)
    }
    public func getdocument(_ request: HTTPRequest, body: NoBody?) async throws -> HTTPResponse {
        let parts = request.path.split(separator: "/")
        guard parts.count >= 4 else { return HTTPResponse(status: 404) }
        let collection = String(parts[1])
        let id = String(parts[3])
        let data = try await service.getDocument(collection: collection, id: id)
        return HTTPResponse(status: 200, headers: ["Content-Type": "application/json"], body: data)
    }
    public func updatedocument(_ request: HTTPRequest, body: updateDocumentRequest?) async throws -> HTTPResponse {
        guard let fields = body else { return HTTPResponse(status: 400) }
        let parts = request.path.split(separator: "/")
        guard parts.count >= 4 else { return HTTPResponse(status: 404) }
        let collection = String(parts[1])
        let id = String(parts[3])
        let comps = URLComponents(string: request.path)
        let dirty = comps?.queryItems?.first(where: { $0.name == "dirty_values" })?.value.flatMap { DirtyValues(rawValue: $0) }
        let data = try await service.updateDocument(collection: collection, id: id, document: fields, dirtyValues: dirty)
        return HTTPResponse(status: 200, headers: ["Content-Type": "application/json"], body: data)
    }
    public func deletedocument(_ request: HTTPRequest, body: NoBody?) async throws -> HTTPResponse {
        let parts = request.path.split(separator: "/")
        guard parts.count >= 4 else { return HTTPResponse(status: 404) }
        let collection = String(parts[1])
        let id = String(parts[3])
        let data = try await service.deleteDocument(collection: collection, id: id)
        return HTTPResponse(status: 200, headers: ["Content-Type": "application/json"], body: data)
    }
    public func getstemmingdictionary(_ request: HTTPRequest, body: NoBody?) async throws -> HTTPResponse {
        let parts = request.path.split(separator: "/")
        guard parts.count >= 3 else { return HTTPResponse(status: 404) }
        let id = String(parts[2])
        let dictionary = try await service.getStemmingDictionary(id: id)
        let data = try JSONEncoder().encode(dictionary)
        return HTTPResponse(status: 200, headers: ["Content-Type": "application/json"], body: data)
    }
    public func retrievemetrics(_ request: HTTPRequest, body: NoBody?) async throws -> HTTPResponse {
        let metrics = try await service.retrieveMetrics()
        let data = try JSONEncoder().encode(metrics)
        return HTTPResponse(status: 200, headers: ["Content-Type": "application/json"], body: data)
    }
    public func importstemmingdictionary(_ request: HTTPRequest, body: importStemmingDictionaryRequest?) async throws -> HTTPResponse {
        guard let content = body else { return HTTPResponse(status: 400) }
        let comps = URLComponents(string: request.path)
        guard let id = comps?.queryItems?.first(where: { $0.name == "id" })?.value else {
            return HTTPResponse(status: 400)
        }
        let data = try await service.importStemmingDictionary(id: id, body: content)
        return HTTPResponse(status: 200, headers: ["Content-Type": "application/octet-stream"], body: data)
    }
    public func importdocuments(_ request: HTTPRequest, body: NoBody?) async throws -> HTTPResponse {
        let parts = request.path.split(separator: "/")
        guard parts.count >= 4 else { return HTTPResponse(status: 404) }
        let collection = String(parts[1])
        let comps = URLComponents(string: request.path)
        var params: [String: String] = [:]
        for item in comps?.queryItems ?? [] { if let value = item.value { params[item.name] = value } }
        let data = try await service.importDocuments(collection: collection, data: request.body, parameters: params.isEmpty ? nil : params)
        return HTTPResponse(status: 200, headers: ["Content-Type": "application/octet-stream"], body: data)
    }
    public func retrieveallpresets(_ request: HTTPRequest, body: NoBody?) async throws -> HTTPResponse {
        let presets = try await service.retrieveAllPresets()
        let data = try JSONEncoder().encode(presets)
        return HTTPResponse(status: 200, headers: ["Content-Type": "application/json"], body: data)
    }
    public func retrieveapistats(_ request: HTTPRequest, body: NoBody?) async throws -> HTTPResponse {
        let stats = try await service.retrieveAPIStats()
        let data = try JSONEncoder().encode(stats)
        return HTTPResponse(status: 200, headers: ["Content-Type": "application/json"], body: data)
    }
    public func retrieveallnlsearchmodels(_ request: HTTPRequest, body: NoBody?) async throws -> HTTPResponse {
        let models = try await service.retrieveAllNLSearchModels()
        let data = try JSONEncoder().encode(models)
        return HTTPResponse(status: 200, headers: ["Content-Type": "application/json"], body: data)
    }
    public func createnlsearchmodel(_ request: HTTPRequest, body: NLSearchModelCreateSchema?) async throws -> HTTPResponse {
        guard let schema = body else { return HTTPResponse(status: 400) }
        let data = try await service.createNLSearchModel(schema: schema)
        return HTTPResponse(status: 201, headers: ["Content-Type": "application/json"], body: data)
    }
    public func getsearchoverride(_ request: HTTPRequest, body: NoBody?) async throws -> HTTPResponse {
        let parts = request.path.split(separator: "/")
        guard parts.count >= 4 else { return HTTPResponse(status: 404) }
        let collection = String(parts[1])
        let id = String(parts[3])
        let override = try await service.getSearchOverride(collection: collection, id: id)
        let data = try JSONEncoder().encode(override)
        return HTTPResponse(status: 200, headers: ["Content-Type": "application/json"], body: data)
    }
    public func upsertsearchoverride(_ request: HTTPRequest, body: SearchOverrideSchema?) async throws -> HTTPResponse {
        guard let schema = body else { return HTTPResponse(status: 400) }
        let parts = request.path.split(separator: "/")
        guard parts.count >= 4 else { return HTTPResponse(status: 404) }
        let collection = String(parts[1])
        let id = String(parts[3])
        let override = try await service.upsertSearchOverride(collection: collection, id: id, schema: schema)
        let data = try JSONEncoder().encode(override)
        return HTTPResponse(status: 200, headers: ["Content-Type": "application/json"], body: data)
    }
    public func deletesearchoverride(_ request: HTTPRequest, body: NoBody?) async throws -> HTTPResponse {
        let parts = request.path.split(separator: "/")
        guard parts.count >= 4 else { return HTTPResponse(status: 404) }
        let collection = String(parts[1])
        let id = String(parts[3])
        let result = try await service.deleteSearchOverride(collection: collection, id: id)
        let data = try JSONEncoder().encode(result)
        return HTTPResponse(status: 200, headers: ["Content-Type": "application/json"], body: data)
    }
    public func getaliases(_ request: HTTPRequest, body: NoBody?) async throws -> HTTPResponse {
        let aliases = try await service.getAliases()
        let data = try JSONEncoder().encode(aliases)
        return HTTPResponse(status: 200, headers: ["Content-Type": "application/json"], body: data)
    }
    public func retrievestopwordsset(_ request: HTTPRequest, body: NoBody?) async throws -> HTTPResponse {
        let parts = request.path.split(separator: "/")
        guard parts.count >= 2 else { return HTTPResponse(status: 404) }
        let id = String(parts[1])
        let result = try await service.retrieveStopwordsSet(id: id)
        let data = try JSONEncoder().encode(result)
        return HTTPResponse(status: 200, headers: ["Content-Type": "application/json"], body: data)
    }
    public func upsertstopwordsset(_ request: HTTPRequest, body: StopwordsSetUpsertSchema?) async throws -> HTTPResponse {
        guard let schema = body else { return HTTPResponse(status: 400) }
        let parts = request.path.split(separator: "/")
        guard parts.count >= 2 else { return HTTPResponse(status: 404) }
        let id = String(parts[1])
        let result = try await service.upsertStopwordsSet(id: id, schema: schema)
        let data = try JSONEncoder().encode(result)
        return HTTPResponse(status: 200, headers: ["Content-Type": "application/json"], body: data)
    }
    public func deletestopwordsset(_ request: HTTPRequest, body: NoBody?) async throws -> HTTPResponse {
        let parts = request.path.split(separator: "/")
        guard parts.count >= 2 else { return HTTPResponse(status: 404) }
        let id = String(parts[1])
        let result = try await service.deleteStopwordsSet(id: id)
        let data = try JSONEncoder().encode(result)
        return HTTPResponse(status: 200, headers: ["Content-Type": "application/json"], body: data)
    }
    public func retrievepreset(_ request: HTTPRequest, body: NoBody?) async throws -> HTTPResponse {
        let parts = request.path.split(separator: "/")
        guard parts.count >= 2 else { return HTTPResponse(status: 404) }
        let id = String(parts[1])
        let preset = try await service.retrievePreset(id: id)
        let data = try JSONEncoder().encode(preset)
        return HTTPResponse(status: 200, headers: ["Content-Type": "application/json"], body: data)
    }
    public func upsertpreset(_ request: HTTPRequest, body: PresetUpsertSchema?) async throws -> HTTPResponse {
        guard let schema = body else { return HTTPResponse(status: 400) }
        let parts = request.path.split(separator: "/")
        guard parts.count >= 2 else { return HTTPResponse(status: 404) }
        let id = String(parts[1])
        let preset = try await service.upsertPreset(id: id, schema: schema)
        let data = try JSONEncoder().encode(preset)
        return HTTPResponse(status: 200, headers: ["Content-Type": "application/json"], body: data)
    }
    public func deletepreset(_ request: HTTPRequest, body: NoBody?) async throws -> HTTPResponse {
        let parts = request.path.split(separator: "/")
        guard parts.count >= 2 else { return HTTPResponse(status: 404) }
        let id = String(parts[1])
        let result = try await service.deletePreset(id: id)
        let data = try JSONEncoder().encode(result)
        return HTTPResponse(status: 200, headers: ["Content-Type": "application/json"], body: data)
    }
    public func getsearchsynonyms(_ request: HTTPRequest, body: NoBody?) async throws -> HTTPResponse {
        let parts = request.path.split(separator: "/")
        guard parts.count >= 3 else { return HTTPResponse(status: 404) }
        let collection = String(parts[1])
        let synonyms = try await service.getSearchSynonyms(collection: collection)
        let data = try JSONEncoder().encode(synonyms)
        return HTTPResponse(status: 200, headers: ["Content-Type": "application/json"], body: data)
    }
    public func getschemachanges(_ request: HTTPRequest, body: NoBody?) async throws -> HTTPResponse {
        let changes = try await service.getSchemaChanges()
        let data = try JSONEncoder().encode(changes)
        return HTTPResponse(status: 200, headers: ["Content-Type": "application/json"], body: data)
    }
    public func getsearchsynonym(_ request: HTTPRequest, body: NoBody?) async throws -> HTTPResponse {
        let parts = request.path.split(separator: "/")
        guard parts.count >= 4 else { return HTTPResponse(status: 404) }
        let collection = String(parts[1])
        let id = String(parts[3])
        let synonym = try await service.getSearchSynonym(collection: collection, id: id)
        let data = try JSONEncoder().encode(synonym)
        return HTTPResponse(status: 200, headers: ["Content-Type": "application/json"], body: data)
    }
    public func upsertsearchsynonym(_ request: HTTPRequest, body: SearchSynonymSchema?) async throws -> HTTPResponse {
        guard let schema = body else { return HTTPResponse(status: 400) }
        let parts = request.path.split(separator: "/")
        guard parts.count >= 4 else { return HTTPResponse(status: 404) }
        let collection = String(parts[1])
        let id = String(parts[3])
        let synonym = try await service.upsertSearchSynonym(collection: collection, id: id, schema: schema)
        let data = try JSONEncoder().encode(synonym)
        return HTTPResponse(status: 200, headers: ["Content-Type": "application/json"], body: data)
    }
    public func deletesearchsynonym(_ request: HTTPRequest, body: NoBody?) async throws -> HTTPResponse {
        let parts = request.path.split(separator: "/")
        guard parts.count >= 4 else { return HTTPResponse(status: 404) }
        let collection = String(parts[1])
        let id = String(parts[3])
        let result = try await service.deleteSearchSynonym(collection: collection, id: id)
        let data = try JSONEncoder().encode(result)
        return HTTPResponse(status: 200, headers: ["Content-Type": "application/json"], body: data)
    }
    public func debug(_ request: HTTPRequest, body: NoBody?) async throws -> HTTPResponse {
        let info = try await service.debug()
        let data = try JSONEncoder().encode(info)
        return HTTPResponse(status: 200, headers: ["Content-Type": "application/json"], body: data)
    }
    public func health(_ request: HTTPRequest, body: NoBody?) async throws -> HTTPResponse {
        let status = try await service.health()
        let data = try JSONEncoder().encode(status)
        return HTTPResponse(status: 200, headers: ["Content-Type": "application/json"], body: data)
    }
    public func getkey(_ request: HTTPRequest, body: NoBody?) async throws -> HTTPResponse {
        let parts = request.path.split(separator: "/")
        guard parts.count >= 2, let id = Int(parts[1]) else { return HTTPResponse(status: 404) }
        let key = try await service.getKey(id: id)
        let data = try JSONEncoder().encode(key)
        return HTTPResponse(status: 200, headers: ["Content-Type": "application/json"], body: data)
    }
    public func deletekey(_ request: HTTPRequest, body: NoBody?) async throws -> HTTPResponse {
        let parts = request.path.split(separator: "/")
        guard parts.count >= 2, let id = Int(parts[1]) else { return HTTPResponse(status: 404) }
        let result = try await service.deleteKey(id: id)
        let data = try JSONEncoder().encode(result)
        return HTTPResponse(status: 200, headers: ["Content-Type": "application/json"], body: data)
    }
    public func searchcollection(_ request: HTTPRequest, body: NoBody?) async throws -> HTTPResponse {
        let parts = request.path.split(separator: "/")
        guard parts.count >= 4 else { return HTTPResponse(status: 404) }
        let collection = String(parts[1])
        let comps = URLComponents(string: request.path)
        let params = comps?.queryItems?.first(where: { $0.name == "searchParameters" })?.value ?? "{}"
        let result = try await service.search(collection: collection, parameters: params)
        let data = try JSONEncoder().encode(result)
        return HTTPResponse(status: 200, headers: ["Content-Type": "application/json"], body: data)
    }
    public func retrievestopwordssets(_ request: HTTPRequest, body: NoBody?) async throws -> HTTPResponse {
        let sets = try await service.retrieveStopwordsSets()
        let data = try JSONEncoder().encode(sets)
        return HTTPResponse(status: 200, headers: ["Content-Type": "application/json"], body: data)
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
