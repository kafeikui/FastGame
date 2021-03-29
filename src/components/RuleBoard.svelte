<script>
</script>

<div class="ruleBoard">
	<div>
		Rule 
		<slot name="mode">
			<span class="missing">0</span>
		</slot>
	</div>
	<div>
		By 
		<slot name="role">
			<span class="missing">AI</span>
		</slot>
	</div>
</div>

<style>
	.ruleBoard {
		display: flex;
		flex-direction: column;
		justify-content: center;
		align-items: center;
		width: 120px;
		font-size: 1.5em;
	}

	.missing {
		color: #999;
	}
</style>
