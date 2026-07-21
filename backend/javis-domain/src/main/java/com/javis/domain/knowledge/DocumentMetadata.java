package com.javis.domain.knowledge;

import java.util.Map;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DocumentMetadata {

    /** 文档来源 URL */
    private String sourceUrl;

    /** 文档作者 */
    private String author;

    /** 文档标签 */
    private java.util.List<String> tags;

    /** 扩展属性 */
    private Map<String, Object> properties;
}
