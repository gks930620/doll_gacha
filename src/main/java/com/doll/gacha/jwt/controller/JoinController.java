package com.doll.gacha.jwt.controller;

import com.doll.gacha.jwt.model.JoinDTO;
import com.doll.gacha.jwt.service.JoinService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseBody;

@Controller
@RequestMapping("/api/join")
@RequiredArgsConstructor
public class JoinController {

    private  final JoinService joinService;

    @ResponseBody
    @PostMapping
    public  String joinPost(@RequestBody JoinDTO joinDTO){ //클라이언트가 body로 보낸다고 가정.
        joinService.joinProcess(joinDTO);
        return "회원가입 완료!";
    }
}
