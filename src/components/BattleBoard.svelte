<script>
	import Battlecard from "./Battlecard.svelte";
	import Points from "./Points.svelte";
	export let points, battlecard;
</script>

<div class="battleboard">
	<div class="points">
		<slot name="points">
			<Points value={points} />
		</slot>
	</div>
	<slot name="battlecard">
		<Battlecard card={battlecard} />
	</slot>
</div>

<style>
	.points {
		display: flex;
		justify-content: center;
	}
	.battleboard {
		width: 220px;
		height: 360px;
		border-radius: 2px;
		padding: 0;
		margin: 0 0 1em 0;
	}
</style>
