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
public class ChunkMetadata {

    /** 所在页码（PDF 等分页文档） */
    private Integer pageNumber;

    /** 章节标题 */
    private String sectionTitle;

    /** 扩展属性 */
    private Map<String, Object> properties;
}
