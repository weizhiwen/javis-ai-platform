package com.javis.domain.common;

import java.util.UUID;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.NoRepositoryBean;

@NoRepositoryBean
public interface BaseRepository<T extends BaseEntity> extends JpaRepository<T, UUID> {

    @Modifying
    @Query(
            "UPDATE #{#entityName} e SET e.deleted = true, e.updatedAt = CURRENT_TIMESTAMP WHERE e.id = :id")
    void softDeleteById(UUID id);

    @Query("SELECT e FROM #{#entityName} e")
    Page<T> findAllIncludingDeleted(Pageable pageable);

    @Query("SELECT e FROM #{#entityName} e WHERE e.id = :id")
    java.util.Optional<T> findByIdIncludingDeleted(UUID id);
}
