package com.javis.domain.knowledge;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import com.javis.domain.common.BaseEntity;
import com.javis.domain.user.User;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToMany;
import jakarta.persistence.Table;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Entity
@Table(name = "knowledge_bases")
public class KnowledgeBase extends BaseEntity {

    @NotBlank
    @Column(nullable = false)
    private String name;

    @Column private String description;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "creator_id")
    private User creator;

    /** 用于向量化的嵌入模型 ID */
    @Column(name = "embedding_model_id")
    private UUID embeddingModelId;

    @Min(100)
    @Column(name = "chunk_size")
    private Integer chunkSize = 500;

    @Min(0)
    @Column(name = "chunk_overlap")
    private Integer chunkOverlap = 50;

    @Column(name = "document_count")
    private Integer documentCount = 0;

    /** 知识库包含的文档列表 */
    @OneToMany(mappedBy = "knowledgeBase", fetch = FetchType.LAZY)
    private List<Document> documents = new ArrayList<>();

    public void addDocument(Document document) {
        this.documents.add(document);
        document.setKnowledgeBase(this);
        this.documentCount = this.documents.size();
    }

    public void removeDocument(Document document) {
        this.documents.remove(document);
        document.setKnowledgeBase(null);
        this.documentCount = this.documents.size();
    }

    public void setChunkSize(Integer chunkSize) {
        if (chunkSize != null && this.chunkOverlap != null && chunkSize <= this.chunkOverlap) {
            throw new IllegalArgumentException("chunkSize must be greater than chunkOverlap");
        }
        this.chunkSize = chunkSize;
    }

    public void setChunkOverlap(Integer chunkOverlap) {
        if (chunkOverlap != null && this.chunkSize != null && chunkOverlap >= this.chunkSize) {
            throw new IllegalArgumentException("chunkOverlap must be less than chunkSize");
        }
        this.chunkOverlap = chunkOverlap;
    }

    public void cascadeSoftDelete() {
        this.softDelete();
        this.documents.forEach(Document::cascadeSoftDelete);
    }
}
