package com.javis.domain.knowledge;

import java.util.ArrayList;
import java.util.List;

import com.javis.domain.common.BaseEntity;

import jakarta.persistence.Column;
import jakarta.persistence.Convert;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToMany;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Entity
@Table(name = "documents")
public class Document extends BaseEntity {

    @Column(nullable = false)
    private String name;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "knowledge_base_id", nullable = false)
    private KnowledgeBase knowledgeBase;

    @Column(name = "file_path")
    private String filePath;

    @Column(name = "file_size")
    private Long fileSize;

    @Column(name = "mime_type")
    private String mimeType;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false)
    private DocumentStatus status = DocumentStatus.PENDING;

    @Column(name = "chunk_count")
    private Integer chunkCount = 0;

    /** 文档元数据 */
    @Convert(converter = DocumentMetadataConverter.class)
    @Column(columnDefinition = "jsonb")
    private DocumentMetadata metadata;

    /** 文档包含的分块列表 */
    @OneToMany(mappedBy = "document", fetch = FetchType.LAZY)
    private List<Chunk> chunks = new ArrayList<>();

    public void addChunk(Chunk chunk) {
        this.chunks.add(chunk);
        chunk.setDocument(this);
        this.chunkCount = this.chunks.size();
    }

    public void cascadeSoftDelete() {
        this.softDelete();
        this.chunks.forEach(Chunk::softDelete);
    }

    public enum DocumentStatus {
        PENDING,
        PROCESSING,
        COMPLETED,
        FAILED
    }
}
