package com.javis.agent.service;

import org.springframework.stereotype.Service;

import com.embabel.agent.api.invocation.AgentInvocation;
import com.embabel.agent.core.AgentPlatform;
import com.javis.agent.core.GreetingAgent;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class AgentExecutionService {

    private final AgentPlatform agentPlatform;

    public String executeGreeting(String userInput) {
        var input = new GreetingAgent.UserInput(userInput);

        var invocation =
                AgentInvocation.create(agentPlatform, GreetingAgent.GreetingResponse.class);
        var result = invocation.invoke(input);

        return result.message();
    }
}
