<script>
	import { afterUpdate } from "svelte";
	export let win;
	let oball;
	afterUpdate(() => {
		if (win) {
			oball.style.background =
				"url(/images/winball.jpg) no-repeat center center";
		} else {
			oball.style.background = "";
		}
	});
</script>

<div class="ball" bind:this={oball}>
	<slot />
</div>

<style>
	.ball {
		width: 48px;
		height: 48px;
		border: 1px solid #aaa;
		border-radius: 30px;
		box-shadow: 2px 2px 8px rgba(0, 0, 0, 0.1);
		padding: 0;
		margin: 0 0 0.5em 0;
		background-size: 60px !important;
		/* opacity: 0.6; */
	}
</style>
