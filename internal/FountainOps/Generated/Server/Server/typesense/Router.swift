import Foundation

public struct Router {
    public var handlers: Handlers

    public init(handlers: Handlers = Handlers()) {
        self.handlers = handlers
    }

    public func route(_ request: HTTPRequest) async throws -> HTTPResponse {
        if request.method == "GET" && request.path.starts(with: "/collections/") {
            let parts = request.path.split(separator: "/")
            if parts.count == 2 {
                let body = try? JSONDecoder().decode(NoBody.self, from: request.body)
                return try await handlers.getcollection(request, body: body)
            }
        }
        switch (request.method, request.path) {
        case ("GET", "/collections/{collectionName}/overrides"):
            let body = try? JSONDecoder().decode(NoBody.self, from: request.body)
            return try await handlers.getsearchoverrides(request, body: body)
        case ("GET", "/collections/{collectionName}/documents/export"):
            let body = try? JSONDecoder().decode(NoBody.self, from: request.body)
            return try await handlers.exportdocuments(request, body: body)
        case ("POST", "/collections/{collectionName}/documents"):
            let body = try? JSONDecoder().decode(indexDocumentRequest.self, from: request.body)
            return try await handlers.indexdocument(request, body: body)
        case ("PATCH", "/collections/{collectionName}/documents"):
            let body = try? JSONDecoder().decode(updateDocumentsRequest.self, from: request.body)
            return try await handlers.updatedocuments(request, body: body)
        case ("DELETE", "/collections/{collectionName}/documents"):
            let body = try? JSONDecoder().decode(NoBody.self, from: request.body)
            return try await handlers.deletedocuments(request, body: body)
        case ("POST", "/analytics/events"):
            let body = try? JSONDecoder().decode(AnalyticsEventCreateSchema.self, from: request.body)
            return try await handlers.createanalyticsevent(request, body: body)
        case ("GET", "/analytics/rules/{ruleName}"):
            let body = try? JSONDecoder().decode(NoBody.self, from: request.body)
            return try await handlers.retrieveanalyticsrule(request, body: body)
        case ("PUT", "/analytics/rules/{ruleName}"):
            let body = try? JSONDecoder().decode(AnalyticsRuleUpsertSchema.self, from: request.body)
            return try await handlers.upsertanalyticsrule(request, body: body)
        case ("DELETE", "/analytics/rules/{ruleName}"):
            let body = try? JSONDecoder().decode(NoBody.self, from: request.body)
            return try await handlers.deleteanalyticsrule(request, body: body)
        case ("GET", "/stemming/dictionaries"):
            let body = try? JSONDecoder().decode(NoBody.self, from: request.body)
            return try await handlers.liststemmingdictionaries(request, body: body)
        case ("GET", "/collections"):
            let body = try? JSONDecoder().decode(NoBody.self, from: request.body)
            return try await handlers.getcollections(request, body: body)
        case ("POST", "/collections"):
            let body = try? JSONDecoder().decode(CollectionSchema.self, from: request.body)
            return try await handlers.createcollection(request, body: body)
        case ("GET", "/conversations/models"):
            let body = try? JSONDecoder().decode(NoBody.self, from: request.body)
            return try await handlers.retrieveallconversationmodels(request, body: body)
        case ("POST", "/conversations/models"):
            let body = try? JSONDecoder().decode(ConversationModelCreateSchema.self, from: request.body)
            return try await handlers.createconversationmodel(request, body: body)
        case ("GET", "/collections/{collectionName}"):
            let body = try? JSONDecoder().decode(NoBody.self, from: request.body)
            return try await handlers.getcollection(request, body: body)
        case ("PATCH", "/collections/{collectionName}"):
            let body = try? JSONDecoder().decode(CollectionUpdateSchema.self, from: request.body)
            return try await handlers.updatecollection(request, body: body)
        case ("DELETE", "/collections/{collectionName}"):
            let body = try? JSONDecoder().decode(NoBody.self, from: request.body)
            return try await handlers.deletecollection(request, body: body)
        case ("GET", "/keys"):
            let body = try? JSONDecoder().decode(NoBody.self, from: request.body)
            return try await handlers.getkeys(request, body: body)
        case ("POST", "/keys"):
            let body = try? JSONDecoder().decode(ApiKeySchema.self, from: request.body)
            return try await handlers.createkey(request, body: body)
        case ("POST", "/operations/vote"):
            let body = try? JSONDecoder().decode(NoBody.self, from: request.body)
            return try await handlers.vote(request, body: body)
        case ("GET", "/analytics/rules"):
            let body = try? JSONDecoder().decode(NoBody.self, from: request.body)
            return try await handlers.retrieveanalyticsrules(request, body: body)
        case ("POST", "/analytics/rules"):
            let body = try? JSONDecoder().decode(AnalyticsRuleSchema.self, from: request.body)
            return try await handlers.createanalyticsrule(request, body: body)
        case ("GET", "/aliases/{aliasName}"):
            let body = try? JSONDecoder().decode(NoBody.self, from: request.body)
            return try await handlers.getalias(request, body: body)
        case ("PUT", "/aliases/{aliasName}"):
            let body = try? JSONDecoder().decode(CollectionAliasSchema.self, from: request.body)
            return try await handlers.upsertalias(request, body: body)
        case ("DELETE", "/aliases/{aliasName}"):
            let body = try? JSONDecoder().decode(NoBody.self, from: request.body)
            return try await handlers.deletealias(request, body: body)
        case ("GET", "/conversations/models/{modelId}"):
            let body = try? JSONDecoder().decode(NoBody.self, from: request.body)
            return try await handlers.retrieveconversationmodel(request, body: body)
        case ("PUT", "/conversations/models/{modelId}"):
            let body = try? JSONDecoder().decode(ConversationModelUpdateSchema.self, from: request.body)
            return try await handlers.updateconversationmodel(request, body: body)
        case ("DELETE", "/conversations/models/{modelId}"):
            let body = try? JSONDecoder().decode(NoBody.self, from: request.body)
            return try await handlers.deleteconversationmodel(request, body: body)
        case ("POST", "/operations/snapshot"):
            let body = try? JSONDecoder().decode(NoBody.self, from: request.body)
            return try await handlers.takesnapshot(request, body: body)
        case ("POST", "/multi_search"):
            let body = try? JSONDecoder().decode(MultiSearchSearchesParameter.self, from: request.body)
            return try await handlers.multisearch(request, body: body)
        case ("GET", "/nl_search_models/{modelId}"):
            let body = try? JSONDecoder().decode(NoBody.self, from: request.body)
            return try await handlers.retrievenlsearchmodel(request, body: body)
        case ("PUT", "/nl_search_models/{modelId}"):
            let body = try? JSONDecoder().decode(NLSearchModelUpdateSchema.self, from: request.body)
            return try await handlers.updatenlsearchmodel(request, body: body)
        case ("DELETE", "/nl_search_models/{modelId}"):
            let body = try? JSONDecoder().decode(NoBody.self, from: request.body)
            return try await handlers.deletenlsearchmodel(request, body: body)
        case ("GET", "/collections/{collectionName}/documents/{documentId}"):
            let body = try? JSONDecoder().decode(NoBody.self, from: request.body)
            return try await handlers.getdocument(request, body: body)
        case ("PATCH", "/collections/{collectionName}/documents/{documentId}"):
            let body = try? JSONDecoder().decode(updateDocumentRequest.self, from: request.body)
            return try await handlers.updatedocument(request, body: body)
        case ("DELETE", "/collections/{collectionName}/documents/{documentId}"):
            let body = try? JSONDecoder().decode(NoBody.self, from: request.body)
            return try await handlers.deletedocument(request, body: body)
        case ("GET", "/stemming/dictionaries/{dictionaryId}"):
            let body = try? JSONDecoder().decode(NoBody.self, from: request.body)
            return try await handlers.getstemmingdictionary(request, body: body)
        case ("GET", "/metrics.json"):
            let body = try? JSONDecoder().decode(NoBody.self, from: request.body)
            return try await handlers.retrievemetrics(request, body: body)
        case ("POST", "/stemming/dictionaries/import"):
            let body = try? JSONDecoder().decode(importStemmingDictionaryRequest.self, from: request.body)
            return try await handlers.importstemmingdictionary(request, body: body)
        case ("POST", "/collections/{collectionName}/documents/import"):
            let body = try? JSONDecoder().decode(NoBody.self, from: request.body)
            return try await handlers.importdocuments(request, body: body)
        case ("GET", "/presets"):
            let body = try? JSONDecoder().decode(NoBody.self, from: request.body)
            return try await handlers.retrieveallpresets(request, body: body)
        case ("GET", "/stats.json"):
            let body = try? JSONDecoder().decode(NoBody.self, from: request.body)
            return try await handlers.retrieveapistats(request, body: body)
        case ("GET", "/nl_search_models"):
            let body = try? JSONDecoder().decode(NoBody.self, from: request.body)
            return try await handlers.retrieveallnlsearchmodels(request, body: body)
        case ("POST", "/nl_search_models"):
            let body = try? JSONDecoder().decode(NLSearchModelCreateSchema.self, from: request.body)
            return try await handlers.createnlsearchmodel(request, body: body)
        case ("GET", "/collections/{collectionName}/overrides/{overrideId}"):
            let body = try? JSONDecoder().decode(NoBody.self, from: request.body)
            return try await handlers.getsearchoverride(request, body: body)
        case ("PUT", "/collections/{collectionName}/overrides/{overrideId}"):
            let body = try? JSONDecoder().decode(SearchOverrideSchema.self, from: request.body)
            return try await handlers.upsertsearchoverride(request, body: body)
        case ("DELETE", "/collections/{collectionName}/overrides/{overrideId}"):
            let body = try? JSONDecoder().decode(NoBody.self, from: request.body)
            return try await handlers.deletesearchoverride(request, body: body)
        case ("GET", "/aliases"):
            let body = try? JSONDecoder().decode(NoBody.self, from: request.body)
            return try await handlers.getaliases(request, body: body)
        case ("GET", "/stopwords/{setId}"):
            let body = try? JSONDecoder().decode(NoBody.self, from: request.body)
            return try await handlers.retrievestopwordsset(request, body: body)
        case ("PUT", "/stopwords/{setId}"):
            let body = try? JSONDecoder().decode(StopwordsSetUpsertSchema.self, from: request.body)
            return try await handlers.upsertstopwordsset(request, body: body)
        case ("DELETE", "/stopwords/{setId}"):
            let body = try? JSONDecoder().decode(NoBody.self, from: request.body)
            return try await handlers.deletestopwordsset(request, body: body)
        case ("GET", "/presets/{presetId}"):
            let body = try? JSONDecoder().decode(NoBody.self, from: request.body)
            return try await handlers.retrievepreset(request, body: body)
        case ("PUT", "/presets/{presetId}"):
            let body = try? JSONDecoder().decode(PresetUpsertSchema.self, from: request.body)
            return try await handlers.upsertpreset(request, body: body)
        case ("DELETE", "/presets/{presetId}"):
            let body = try? JSONDecoder().decode(NoBody.self, from: request.body)
            return try await handlers.deletepreset(request, body: body)
        case ("GET", "/collections/{collectionName}/synonyms"):
            let body = try? JSONDecoder().decode(NoBody.self, from: request.body)
            return try await handlers.getsearchsynonyms(request, body: body)
        case ("GET", "/operations/schema_changes"):
            let body = try? JSONDecoder().decode(NoBody.self, from: request.body)
            return try await handlers.getschemachanges(request, body: body)
        case ("GET", "/collections/{collectionName}/synonyms/{synonymId}"):
            let body = try? JSONDecoder().decode(NoBody.self, from: request.body)
            return try await handlers.getsearchsynonym(request, body: body)
        case ("PUT", "/collections/{collectionName}/synonyms/{synonymId}"):
            let body = try? JSONDecoder().decode(SearchSynonymSchema.self, from: request.body)
            return try await handlers.upsertsearchsynonym(request, body: body)
        case ("DELETE", "/collections/{collectionName}/synonyms/{synonymId}"):
            let body = try? JSONDecoder().decode(NoBody.self, from: request.body)
            return try await handlers.deletesearchsynonym(request, body: body)
        case ("GET", "/debug"):
            let body = try? JSONDecoder().decode(NoBody.self, from: request.body)
            return try await handlers.debug(request, body: body)
        case ("GET", "/health"):
            let body = try? JSONDecoder().decode(NoBody.self, from: request.body)
            return try await handlers.health(request, body: body)
        case ("GET", "/keys/{keyId}"):
            let body = try? JSONDecoder().decode(NoBody.self, from: request.body)
            return try await handlers.getkey(request, body: body)
        case ("DELETE", "/keys/{keyId}"):
            let body = try? JSONDecoder().decode(NoBody.self, from: request.body)
            return try await handlers.deletekey(request, body: body)
        case ("GET", "/collections/{collectionName}/documents/search"):
            let body = try? JSONDecoder().decode(NoBody.self, from: request.body)
            return try await handlers.searchcollection(request, body: body)
        case ("GET", "/stopwords"):
            let body = try? JSONDecoder().decode(NoBody.self, from: request.body)
            return try await handlers.retrievestopwordssets(request, body: body)
        default:
            return HTTPResponse(status: 404)
        }
    }
}

© 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
