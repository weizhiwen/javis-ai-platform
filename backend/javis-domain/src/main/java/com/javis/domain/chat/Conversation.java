package com.javis.domain.chat;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import com.javis.domain.agent.Agent;
import com.javis.domain.common.BaseEntity;
import com.javis.domain.user.User;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
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
@Table(name = "conversations")
public class Conversation extends BaseEntity {

    @Column(nullable = false)
    private String title;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "agent_id", nullable = false)
    private Agent agent;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    /** 覆盖 Agent 默认模型 ID，为空则使用 Agent 当前版本的模型 */
    @Column(name = "model_id")
    private UUID modelId;

    /** 最后一条消息的预览文本，用于列表展示 */
    @Column(name = "last_message_preview", length = 200)
    private String lastMessagePreview;

    /** 最后一条消息的时间 */
    @Column(name = "last_message_at")
    private Instant lastMessageAt;

    /** 对话中的消息列表 */
    @OneToMany(mappedBy = "conversation", fetch = FetchType.LAZY)
    private List<Message> messages = new ArrayList<>();

    public void addMessage(Message message) {
        this.messages.add(message);
        message.setConversation(this);
        this.lastMessagePreview =
                message.getContent().length() > 200
                        ? message.getContent().substring(0, 200)
                        : message.getContent();
        this.lastMessageAt = message.getCreatedAt();
    }

    public void cascadeSoftDelete() {
        this.softDelete();
        this.messages.forEach(Message::softDelete);
    }
}
