// Models for Typesense API

public struct APIStatsResponse: Codable {
    public let delete_latency_ms: String
    public let delete_requests_per_second: String
    public let import_latency_ms: String
    public let import_requests_per_second: String
    public let latency_ms: [String: String]
    public let overloaded_requests_per_second: String
    public let pending_write_batches: String
    public let requests_per_second: [String: String]
    public let search_latency_ms: String
    public let search_requests_per_second: String
    public let total_requests_per_second: String
    public let write_latency_ms: String
    public let write_requests_per_second: String
}

public struct AnalyticsEventCreateResponse: Codable {
    public let ok: Bool
}

public struct AnalyticsEventCreateSchema: Codable {
    public let data: [String: String]
    public let name: String
    public let type: String
}

public struct AnalyticsRuleDeleteResponse: Codable {
    public let name: String
}

public struct AnalyticsRuleParameters: Codable {
    public let destination: AnalyticsRuleParametersDestination
    public let expand_query: Bool
    public let limit: Int
    public let source: AnalyticsRuleParametersSource
}

public struct AnalyticsRuleParametersDestination: Codable {
    public let collection: String
    public let counter_field: String
}

public struct AnalyticsRuleParametersSource: Codable {
    public let collections: [String]
    public let events: [[String: String]]
}

public struct AnalyticsRuleUpsertSchema: Codable {
    public let params: AnalyticsRuleParameters
    public let type: String
}

public struct AnalyticsRulesRetrieveSchema: Codable {
    public let rules: [AnalyticsRuleSchema]
}

public struct ApiKeyDeleteResponse: Codable {
    public let id: Int
}

public struct ApiKeySchema: Codable {
    public let actions: [String]
    public let collections: [String]
    public let description: String
    public let expires_at: Int
    public let value: String
}

public struct ApiKeysResponse: Codable {
    public let keys: [ApiKey]
}

public struct ApiResponse: Codable {
    public let message: String
}

public struct CollectionAlias: Codable {
    public let collection_name: String
    public let name: String
}

public struct CollectionAliasSchema: Codable {
    public let collection_name: String
}

public struct CollectionAliasesResponse: Codable {
    public let aliases: [CollectionAlias]
}

public struct CollectionSchema: Codable {
    public let default_sorting_field: String
    public let enable_nested_fields: Bool
    public let fields: [Field]
    public let name: String
    public let symbols_to_index: [String]
    public let token_separators: [String]
    public let voice_query_model: VoiceQueryModelCollectionConfig
}

public struct CollectionUpdateSchema: Codable {
    public let fields: [Field]
}

public struct ConversationModelUpdateSchema: Codable {
    public let account_id: String
    public let api_key: String
    public let history_collection: String
    public let id: String
    public let max_bytes: Int
    public let model_name: String
    public let system_prompt: String
    public let ttl: Int
    public let vllm_url: String
}

public enum DirtyValues: String, Codable {
    case coerce_or_reject
    case coerce_or_drop
    case drop
    case reject
}

public enum DropTokensMode: String, Codable {
    case right_to_left
    case left_to_right
    case both_sides:3
}

public struct FacetCounts: Codable {
    public let counts: [[String: String]]
    public let field_name: String
    public let stats: [String: String]
}

public struct Field: Codable {
    public let drop: Bool
    public let embed: [String: String]
    public let facet: Bool
    public let index: Bool
    public let infix: Bool
    public let locale: String
    public let name: String
    public let num_dim: Int
    public let optional: Bool
    public let range_index: Bool
    public let reference: String
    public let sort: Bool
    public let stem: Bool
    public let stem_dictionary: String
    public let store: Bool
    public let symbols_to_index: [String]
    public let token_separators: [String]
    public let type: String
    public let vec_dist: String
}

public struct HealthStatus: Codable {
    public let ok: Bool
}

public enum IndexAction: String, Codable {
    case create
    case update
    case upsert
    case emplace
}

public struct MultiSearchParameters: Codable {
    public let cache_ttl: Int
    public let conversation: Bool
    public let conversation_id: String
    public let conversation_model_id: String
    public let drop_tokens_mode: DropTokensMode
    public let drop_tokens_threshold: Int
    public let enable_overrides: Bool
    public let enable_synonyms: Bool
    public let enable_typos_for_alpha_numerical_tokens: Bool
    public let enable_typos_for_numerical_tokens: Bool
    public let exclude_fields: String
    public let exhaustive_search: Bool
    public let facet_by: String
    public let facet_query: String
    public let facet_return_parent: String
    public let facet_strategy: String
    public let filter_by: String
    public let filter_curated_hits: Bool
    public let group_by: String
    public let group_limit: Int
    public let group_missing_values: Bool
    public let hidden_hits: String
    public let highlight_affix_num_tokens: Int
    public let highlight_end_tag: String
    public let highlight_fields: String
    public let highlight_full_fields: String
    public let highlight_start_tag: String
    public let include_fields: String
    public let infix: String
    public let limit: Int
    public let max_extra_prefix: Int
    public let max_extra_suffix: Int
    public let max_facet_values: Int
    public let min_len_1typo: Int
    public let min_len_2typo: Int
    public let num_typos: String
    public let offset: Int
    public let override_tags: String
    public let page: Int
    public let per_page: Int
    public let pinned_hits: String
    public let pre_segmented_query: Bool
    public let prefix: String
    public let preset: String
    public let prioritize_exact_match: Bool
    public let prioritize_num_matching_fields: Bool
    public let prioritize_token_position: Bool
    public let q: String
    public let query_by: String
    public let query_by_weights: String
    public let remote_embedding_num_tries: Int
    public let remote_embedding_timeout_ms: Int
    public let search_cutoff_ms: Int
    public let snippet_threshold: Int
    public let sort_by: String
    public let stopwords: String
    public let synonym_num_typos: Int
    public let synonym_prefix: Bool
    public let text_match_type: String
    public let typo_tokens_threshold: Int
    public let use_cache: Bool
    public let vector_query: String
    public let voice_query: String
}

public struct MultiSearchResult: Codable {
    public let conversation: SearchResultConversation
    public let results: [MultiSearchResultItem]
}

public struct MultiSearchSearchesParameter: Codable {
    public let searches: [MultiSearchCollectionParameters]
    public let union: Bool
}

public struct NLSearchModelBase: Codable {
    public let access_token: String
    public let account_id: String
    public let api_key: String
    public let api_url: String
    public let api_version: String
    public let client_id: String
    public let client_secret: String
    public let max_bytes: Int
    public let max_output_tokens: Int
    public let model_name: String
    public let project_id: String
    public let refresh_token: String
    public let region: String
    public let stop_sequences: [String]
    public let system_prompt: String
    public let temperature: String
    public let top_k: Int
    public let top_p: String
}

public struct NLSearchModelDeleteSchema: Codable {
    public let id: String
}

public struct PresetDeleteSchema: Codable {
    public let name: String
}

public struct PresetsRetrieveSchema: Codable {
    public let presets: [PresetSchema]
}

public struct SchemaChangeStatus: Codable {
    public let altered_docs: Int
    public let collection: String
    public let validated_docs: Int
}

public struct SearchGroupedHit: Codable {
    public let found: Int
    public let group_key: [String]
    public let hits: [SearchResultHit]
}

public struct SearchHighlight: Codable {
    public let field: String
    public let indices: [Int]
    public let matched_tokens: [[String: String]]
    public let snippet: String
    public let snippets: [String]
    public let value: String
    public let values: [String]
}

public struct SearchOverrideDeleteResponse: Codable {
    public let id: String
}

public struct SearchOverrideExclude: Codable {
    public let id: String
}

public struct SearchOverrideInclude: Codable {
    public let id: String
    public let position: Int
}

public struct SearchOverrideRule: Codable {
    public let filter_by: String
    public let match: String
    public let query: String
    public let tags: [String]
}

public struct SearchOverrideSchema: Codable {
    public let effective_from_ts: Int
    public let effective_to_ts: Int
    public let excludes: [SearchOverrideExclude]
    public let filter_by: String
    public let filter_curated_hits: Bool
    public let includes: [SearchOverrideInclude]
    public let metadata: [String: String]
    public let remove_matched_tokens: Bool
    public let replace_query: String
    public let rule: SearchOverrideRule
    public let sort_by: String
    public let stop_processing: Bool
}

public struct SearchOverridesResponse: Codable {
    public let overrides: [SearchOverride]
}

public struct SearchParameters: Codable {
    public let cache_ttl: Int
    public let conversation: Bool
    public let conversation_id: String
    public let conversation_model_id: String
    public let drop_tokens_mode: DropTokensMode
    public let drop_tokens_threshold: Int
    public let enable_highlight_v1: Bool
    public let enable_overrides: Bool
    public let enable_synonyms: Bool
    public let enable_typos_for_alpha_numerical_tokens: Bool
    public let enable_typos_for_numerical_tokens: Bool
    public let exclude_fields: String
    public let exhaustive_search: Bool
    public let facet_by: String
    public let facet_query: String
    public let facet_return_parent: String
    public let facet_strategy: String
    public let filter_by: String
    public let filter_curated_hits: Bool
    public let group_by: String
    public let group_limit: Int
    public let group_missing_values: Bool
    public let hidden_hits: String
    public let highlight_affix_num_tokens: Int
    public let highlight_end_tag: String
    public let highlight_fields: String
    public let highlight_full_fields: String
    public let highlight_start_tag: String
    public let include_fields: String
    public let infix: String
    public let limit: Int
    public let max_candidates: Int
    public let max_extra_prefix: Int
    public let max_extra_suffix: Int
    public let max_facet_values: Int
    public let max_filter_by_candidates: Int
    public let min_len_1typo: Int
    public let min_len_2typo: Int
    public let nl_model_id: String
    public let nl_query: Bool
    public let num_typos: String
    public let offset: Int
    public let override_tags: String
    public let page: Int
    public let per_page: Int
    public let pinned_hits: String
    public let pre_segmented_query: Bool
    public let prefix: String
    public let preset: String
    public let prioritize_exact_match: Bool
    public let prioritize_num_matching_fields: Bool
    public let prioritize_token_position: Bool
    public let q: String
    public let query_by: String
    public let query_by_weights: String
    public let remote_embedding_num_tries: Int
    public let remote_embedding_timeout_ms: Int
    public let search_cutoff_ms: Int
    public let snippet_threshold: Int
    public let sort_by: String
    public let split_join_tokens: String
    public let stopwords: String
    public let synonym_num_typos: Int
    public let synonym_prefix: Bool
    public let text_match_type: String
    public let typo_tokens_threshold: Int
    public let use_cache: Bool
    public let vector_query: String
    public let voice_query: String
}

public struct SearchResult: Codable {
    public let conversation: SearchResultConversation
    public let facet_counts: [FacetCounts]
    public let found: Int
    public let found_docs: Int
    public let grouped_hits: [SearchGroupedHit]
    public let hits: [SearchResultHit]
    public let out_of: Int
    public let page: Int
    public let request_params: [String: String]
    public let search_cutoff: Bool
    public let search_time_ms: Int
}

public struct SearchResultConversation: Codable {
    public let answer: String
    public let conversation_history: [[String: String]]
    public let conversation_id: String
    public let query: String
}

public struct SearchResultHit: Codable {
    public let document: [String: [String: String]]
    public let geo_distance_meters: [String: Int]
    public let highlight: [String: String]
    public let highlights: [SearchHighlight]
    public let text_match: Int
    public let text_match_info: [String: String]
    public let vector_distance: String
}

public struct SearchSynonymDeleteResponse: Codable {
    public let id: String
}

public struct SearchSynonymSchema: Codable {
    public let locale: String
    public let root: String
    public let symbols_to_index: [String]
    public let synonyms: [String]
}

public struct SearchSynonym: Codable {
    public let locale: String
    public let root: String
    public let symbols_to_index: [String]
    public let synonyms: [String]
    public let id: String
}

public struct SearchSynonymsResponse: Codable {
    public let synonyms: [SearchSynonym]
}

public struct StemmingDictionary: Codable {
    public let id: String
    public let words: [[String: String]]
}

public struct StopwordsSetRetrieveSchema: Codable {
    public let stopwords: StopwordsSetSchema
}

public struct StopwordsSetSchema: Codable {
    public let id: String
    public let locale: String
    public let stopwords: [String]
}

public struct StopwordsSetUpsertSchema: Codable {
    public let locale: String
    public let stopwords: [String]
}

public struct StopwordsSetsRetrieveAllSchema: Codable {
    public let stopwords: [StopwordsSetSchema]
}

public struct SuccessStatus: Codable {
    public let success: Bool
}

public struct VoiceQueryModelCollectionConfig: Codable {
    public let model_name: String
}

public typealias indexDocumentRequest = [String: String]

public typealias updateDocumentsRequest = [String: String]

public typealias updateDocumentRequest = [String: String]

public typealias updateDocumentResponse = [String: String]

public struct updateDocumentsResponse: Codable {
    public let num_updated: Int
}

public struct deleteDocumentsResponse: Codable {
    public let num_deleted: Int
}

public struct listStemmingDictionariesResponse: Codable {
    public let dictionaries: [String]
}

public typealias getCollectionsResponse = [CollectionResponse]

public typealias retrieveAllConversationModelsResponse = [ConversationModelSchema]

public typealias getDocumentResponse = [String: String]

public typealias deleteDocumentResponse = [String: String]

public typealias retrieveMetricsResponse = [String: String]

public typealias importStemmingDictionaryRequest = String

public typealias retrieveAllNLSearchModelsResponse = [NLSearchModelSchema]

public struct deleteStopwordsSetResponse: Codable {
    public let id: String
}

public typealias getSchemaChangesResponse = [SchemaChangeStatus]

public struct debugResponse: Codable {
    public let version: String
}


© 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
