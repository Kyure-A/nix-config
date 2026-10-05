/** Preserve the two Venice model wire contracts in the DSH pi-ai adapter. */
export function venicePayload(profile, model, payload) {
  if (profile.provider !== 'venice') return payload;
  if (model.id === 'qwen-3-6-plus') {
    return {
      ...payload,
      venice_parameters: {
        ...payload.venice_parameters,
        disable_thinking: true,
      },
    };
  }
  if (model.id === 'e2ee-gemma-4-26b-a4b-uncensored-p') {
    const { tools, tool_choice, parallel_tool_calls, ...textOnly } = payload;
    return textOnly;
  }
  return payload;
}
