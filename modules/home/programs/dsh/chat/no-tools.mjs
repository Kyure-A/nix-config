export const name = 'chat-no-tools';
export const inject = ['tools'];
export function apply(ctx) {
  ctx.effect(() => ctx.tools.restrict({ allow: [] }));
}
