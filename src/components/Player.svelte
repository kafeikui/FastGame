<div class="player">
	<div class="avatar">
		<slot name="avatar">
			<span class="missing" />
		</slot>
	</div>
	<div class="name">
		<slot name="name">
			<span class="missing">Unknown</span>
		</slot>
	</div>
	<div class="level">
		Lv:
		<slot name="level">
			<span class="missing">99</span>
		</slot>
	</div>
	<div class="level">
		Win: 
		<slot name="win">
			<span class="missing">99</span>
		</slot>
	</div>
	<div class="level">
		Lose: 
		<slot name="lose">
			<span class="missing">99</span>
		</slot>
	</div>
	<div class="level">
		Cards: 
		<slot name="cards">
			<span class="missing">99</span>
		</slot>
	</div>
</div>

<style>
	.player {
		width: 140px;
		height: 360px;
		border: 1px solid #aaa;
		border-radius: 2px;
		box-shadow: 2px 2px 8px rgba(0, 0, 0, 0.1);
		padding: 1em;
		margin: 0 0 1em 0;
	}
	.avatar {
		height: 120px;
		padding: 0 0 0.2em 0;
		margin: 1em 0 1em 0;
		text-align: center;
		border-bottom: 1px solid #bdbbbb
	}
	.name,
	.level {
		padding: 0 0 0 1.5em;
		background: 0 0 no-repeat;
		background-size: 20px 20px;
		margin: 0 0 0.5em 0;
		line-height: 1.2;
	}
	.missing {
		color: #999;
	}
</style>
