package com.doll.gacha.controller;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
public class HomeController {

    @GetMapping("/")
    public String home() {
        return "index";
    }

    @GetMapping("/map")
    public String map() {
        return "map";
    }

    @GetMapping("/community")
    public String community() {
        return "community/list";
    }

    @GetMapping("/community/write")
    public String communityWrite() {
        return "community/write";
    }

    @GetMapping("/community/detail")
    public String communityDetail() {
        return "community/detail";
    }

    @GetMapping("/doll")
    public String doll() {
        return "doll/list";
    }

    @GetMapping("/doll/write")
    public String dollWrite() {
        return "doll/write";
    }

    @GetMapping("/doll/detail")
    public String dollDetail() {
        return "doll/detail";
    }
}

