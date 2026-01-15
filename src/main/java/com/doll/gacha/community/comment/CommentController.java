package com.doll.gacha.community.comment;

import com.doll.gacha.community.comment.dto.CommentCreateDTO;
import com.doll.gacha.community.comment.dto.CommentDTO;
import com.doll.gacha.community.comment.dto.CommentUpdateDTO;
import com.doll.gacha.jwt.model.CustomUserAccount;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/comments")
@RequiredArgsConstructor
public class CommentController {

    private final CommentService commentService;

    /**
     * 특정 게시글의 댓글 목록 조회 (페이징)
     */
    @GetMapping("/community/{communityId}")
    public ResponseEntity<Page<CommentDTO>> getComments(
            @PathVariable Long communityId,
            @PageableDefault(size = 10, sort = "createdAt") Pageable pageable) {

        Page<CommentDTO> comments = commentService.getCommentsByCommunityId(communityId, pageable);
        return ResponseEntity.ok(comments);
    }

    /**
     * 댓글 작성 (로그인 필요)
     */
    @PostMapping
    public ResponseEntity<CommentDTO> createComment(
            @Valid @RequestBody CommentCreateDTO createDTO,
            @AuthenticationPrincipal CustomUserAccount userAccount) {

        CommentDTO comment = commentService.createComment(createDTO, userAccount.getUsername());
        return ResponseEntity.status(HttpStatus.CREATED).body(comment);
    }

    /**
     * 댓글 수정 (로그인 필요, 작성자만)
     */
    @PutMapping("/{commentId}")
    public ResponseEntity<CommentDTO> updateComment(
            @PathVariable Long commentId,
            @Valid @RequestBody CommentUpdateDTO updateDTO,
            @AuthenticationPrincipal CustomUserAccount userAccount) {

        CommentDTO comment = commentService.updateComment(commentId, updateDTO, userAccount.getUsername());
        return ResponseEntity.ok(comment);
    }

    /**
     * 댓글 삭제 (로그인 필요, 작성자만)
     */
    @DeleteMapping("/{commentId}")
    public ResponseEntity<Void> deleteComment(
            @PathVariable Long commentId,
            @AuthenticationPrincipal CustomUserAccount userAccount) {
        commentService.deleteComment(commentId, userAccount.getUsername());
        return ResponseEntity.noContent().build();
    }
}

