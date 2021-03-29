<script>
	export let value;
</script>

<div class="points">{value?value:0}</div>

<style>
	.points {
		width: 50px;
		height: 50px;
		border: 1px solid #aaa;
		box-shadow: 2px 2px 8px rgba(0, 0, 0, 0.1);
		padding: 0;
		margin: 0 0 1em 0;
		font-size: 32px;
		text-align: center;
	}
</style>
