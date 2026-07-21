package com.javis.domain.knowledge;

import com.javis.domain.common.BaseEntity;

import jakarta.persistence.Column;
import jakarta.persistence.Convert;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Entity
@Table(name = "chunks")
public class Chunk extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "document_id", nullable = false)
    private Document document;

    /** 冗余关联，优化向量检索时按知识库过滤，避免 JOIN */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "knowledge_base_id", nullable = false)
    private KnowledgeBase knowledgeBase;

    @Column(name = "content", nullable = false, columnDefinition = "TEXT")
    private String content;

    @Column(name = "chunk_index")
    private Integer chunkIndex;

    @Column(name = "token_count")
    private Integer tokenCount;

    @Column(name = "embedding_vector", columnDefinition = "vector(1536)")
    private String embeddingVector;

    /** 分块元数据 */
    @Convert(converter = ChunkMetadataConverter.class)
    @Column(columnDefinition = "jsonb")
    private ChunkMetadata metadata;
}
