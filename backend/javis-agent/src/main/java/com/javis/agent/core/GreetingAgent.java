package com.javis.agent.core;

import com.embabel.agent.api.annotation.AchievesGoal;
import com.embabel.agent.api.annotation.Action;
import com.embabel.agent.api.annotation.Agent;
import com.embabel.agent.api.common.Ai;

import lombok.RequiredArgsConstructor;

@Agent(description = "A simple greeting agent that responds to user queries")
@RequiredArgsConstructor
public class GreetingAgent {

    @AchievesGoal(description = "Generate a greeting response for the user")
    @Action
    public GreetingResponse generateGreeting(UserInput input, Ai ai) {
        String prompt =
                """
            You are a helpful AI assistant. Respond to the following user message
            in a friendly and concise way:

            User: %s

            Assistant:
            """
                        .formatted(input.content());

        String response = ai.withDefaultLlm().generateText(prompt);

        return new GreetingResponse(response);
    }

    public record UserInput(String content) {}

    public record GreetingResponse(String message) {}
}
