FactoryBot.define do
  factory :ci_build_trace_chunk, class: Ci::BuildTraceChunk do
    build factory: :ci_build
    chunk_index 0
    data_store :redis
  end
end
