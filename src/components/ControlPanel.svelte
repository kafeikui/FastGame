<script>
	import { createEventDispatcher } from "svelte";
	export let enablePlay = false;
	export let enableNext = false;
	export let enableRestart = true;
	let oPlayPanel;
	const dispatch1 = createEventDispatcher();
	function play() {
		dispatch1("play", {});
	}
	const dispatch2 = createEventDispatcher();
	function next() {
		dispatch2("next", {});
	}
	const dispatch3 = createEventDispatcher();
	function restart() {
		dispatch2("restart", {});
	}
</script>

<div class="panelBoard">
	<div class="panel">
		<button class="font" disabled={!enablePlay} on:click={play}>
			Play
		</button>
	</div>
	<div class="panel">
		<button class="font" disabled={!enableNext} on:click={next}>
			Continue
		</button>
	</div>
	<div class="panel">
		<button class="font" disabled={!enableRestart} on:click={restart}>
			Restart
		</button>
	</div>
</div>

<style>
	.panelBoard {
		display: flex;
		height: 320px;
		flex-direction: column;
		justify-content: space-between;
		align-items: center;
	}
	.panel {
		width: 120px;
		height: 80px;
		margin: 0.5em;
		text-align: center;
		position: relative;
	}

	.font {
		font-family: "Comic Sans MS", cursive;
		font-size: 1.6em;
	}
</style>
