<script>
	import Winball from "./Winball.svelte";

	export let balls = [
		{ id: "0", win: false },
		{ id: "1", win: false },
	];
	export function printScore() {
		return Number(balls["0"].win) + Number(balls["1"].win);
	}
	export function winPoint() {
		return balls
			.map((e) => (e.win ? 1 : 0))
			.reduce((arr, cur) => arr + cur, 0);
	}
</script>

<div class="board">
	{#each balls as { id, win }, i}
		<Winball {win} />
	{/each}
</div>

<style>
	.board {
		width: 50px;
		height: 160px;
		border: 1px #aaa;
		border-radius: 60px;
		padding: 0;
		margin: 1em;
	}
</style>
