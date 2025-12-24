package com.doll.gacha.controller;

import com.doll.gacha.entity.DollShop;
import com.doll.gacha.entity.Review;
import com.doll.gacha.entity.User;
import com.doll.gacha.repository.DollShopRepository;
import com.doll.gacha.repository.UserRepository;
import com.doll.gacha.service.ReviewService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@Controller
@RequestMapping("/review")
@RequiredArgsConstructor
public class ReviewController {

    private final ReviewService reviewService;
    private final UserRepository userRepository;
    private final DollShopRepository dollShopRepository;

    /**
     * 내 리뷰 목록 (임시로 userId=1 사용)
     */
    @GetMapping("/list")
    public String list(Model model) {
        // TODO: 로그인 구현 후 세션에서 가져오기
        Long currentUserId = 1L;

        List<Review> reviews = reviewService.getMyReviews(currentUserId);
        model.addAttribute("reviews", reviews);

        return "review/list";
    }

    /**
     * 리뷰 작성 폼 (1단계: 가게 검색)
     */
    @GetMapping("/form")
    public String form(Model model) {
        return "review/form";
    }

    /**
     * 리뷰 작성 폼 (2단계: 가게 선택 완료 후)
     */
    @GetMapping("/form/write")
    public String formWrite(@RequestParam Long shopId, Model model) {
        DollShop shop = dollShopRepository.findById(shopId)
                .orElseThrow(() -> new IllegalArgumentException("가게를 찾을 수 없습니다."));

        model.addAttribute("shop", shop);
        return "review/write";
    }

    /**
     * 리뷰 작성 처리
     */
    @PostMapping("/create")
    public String create(@ModelAttribute Review review, @RequestParam Long shopId) {
        // TODO: 로그인 구현 후 세션에서 가져오기
        Long currentUserId = 1L;

        User user = userRepository.findById(currentUserId)
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다."));
        DollShop shop = dollShopRepository.findById(shopId)
                .orElseThrow(() -> new IllegalArgumentException("가게를 찾을 수 없습니다."));

        review.setUser(user);
        review.setDollShop(shop);
        review.setIsDeleted(false);

        reviewService.createReview(review);

        return "redirect:/review/list";
    }

    /**
     * 리뷰 상세 조회
     */
    @GetMapping("/detail/{id}")
    public String detail(@PathVariable Long id, Model model) {
        Review review = reviewService.getReview(id);
        model.addAttribute("review", review);
        return "review/detail";
    }

    /**
     * 리뷰 수정 폼
     */
    @GetMapping("/edit/{id}")
    public String edit(@PathVariable Long id, Model model) {
        Review review = reviewService.getReview(id);
        model.addAttribute("review", review);
        return "review/edit";
    }

    /**
     * 리뷰 수정 처리
     */
    @PostMapping("/update/{id}")
    public String update(@PathVariable Long id, @ModelAttribute Review review) {
        reviewService.updateReview(id, review);
        return "redirect:/review/list";
    }

    /**
     * 리뷰 삭제
     */
    @PostMapping("/delete/{id}")
    public String delete(@PathVariable Long id) {
        reviewService.deleteReview(id);
        return "redirect:/review/list";
    }
}

