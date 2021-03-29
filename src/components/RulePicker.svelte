<script>
	import { createEventDispatcher } from "svelte";
	import { afterUpdate } from "svelte";

	export let onPick = false;
	let oRulePicker;

	// event
	const dispatch = createEventDispatcher();

	afterUpdate(() => {
		if (onPick) {
			oRulePicker.style.display = "flex";
		} else {
			oRulePicker.style.display = "none";
		}
	});
</script>

<div class="rulePicker" bind:this={oRulePicker}>
	<div class="title">
		<p>Cheer up! Pick your preferred rule:</p>
	</div>
	<div>
		<p>
			Rule 1: same type, higher points win! While different type, lower
			points win!
		</p>
		<p>
			Rule 2: same type, lower points win! While different type, higher
			points win!
		</p>
	</div>
	<div class="ruleBoard">
		<button
			class="rule"
			on:click={(e) =>
				dispatch("choose", {
					mode: 1,
				})}>Rule 1</button
		>
		<button
			class="rule"
			on:click={(e) =>
				dispatch("choose", {
					mode: 2,
				})}>Rule 2</button
		>
	</div>
</div>

<style>
	.title {
		font-size: 1.5em;
		/* margin-block-start: 0.83em;
    margin-block-end: 0.83em;
    margin-inline-start: 0px;
    margin-inline-end: 0px; */
		font-weight: bold;
	}
	.rulePicker {
		color: #fff;
		width: 600px;
		height: 400px;
		background-color: #40527e;
		display: none;
		flex-direction: column;
		justify-content: space-between;
		align-items: center;
		border-radius: 10px;
		padding-top: 50px;
		padding-bottom: 50px;
		box-sizing: border-box;
		position: absolute;
		top: 30vh;
		left: 35vw;
		z-index: 1000;
	}
	.ruleBoard {
		justify-content: center;
	}
	.rule {
		color: #fff;
		cursor: pointer;
		width: 160px;
		height: 50px;
		background-color: #02a0a0;
		margin: 1em;
		font-size: 1.2em;
		text-align: center;
		align-items: center;
	}

	.rule:hover {
		background-color: #019191;
	}
</style>
