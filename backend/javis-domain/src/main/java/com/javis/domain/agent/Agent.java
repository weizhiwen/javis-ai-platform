package com.javis.domain.agent;

import java.util.ArrayList;
import java.util.List;

import com.javis.domain.common.BaseEntity;
import com.javis.domain.user.User;

import jakarta.persistence.CascadeType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToMany;
import jakarta.persistence.OneToOne;
import jakarta.persistence.OrderBy;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Entity
@Table(name = "agents")
public class Agent extends BaseEntity {

    /** Agent 名称 */
    @Column(nullable = false)
    private String name;

    /** Agent 描述 */
    @Column private String description;

    /** 头像 URL */
    @Column(name = "avatar_url")
    private String avatarUrl;

    /** 创建者 */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "creator_id")
    private User creator;

    /** 当前生效的版本（最新发布版本） */
    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "current_version_id")
    private AgentVersion currentVersion;

    /** 所有版本历史 */
    @OneToMany(mappedBy = "agent", cascade = CascadeType.ALL, orphanRemoval = true)
    @OrderBy("createdAt DESC")
    private List<AgentVersion> versions = new ArrayList<>();

    public void addVersion(AgentVersion version) {
        this.versions.add(version);
        version.setAgent(this);
    }

    public void removeVersion(AgentVersion version) {
        this.versions.remove(version);
        version.setAgent(null);
        if (this.currentVersion != null && this.currentVersion.equals(version)) {
            this.currentVersion = null;
        }
    }

    public void setCurrentVersion(AgentVersion version) {
        if (!this.versions.contains(version)) {
            throw new IllegalArgumentException(
                    "Version must be added to agent before setting as current");
        }
        this.currentVersion = version;
    }

    public void cascadeSoftDelete() {
        this.softDelete();
        this.versions.forEach(AgentVersion::softDelete);
    }
}
