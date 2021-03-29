<script context="module">
	let pookers = [];
	let num = [
		"A",
		"2",
		"3",
		"4",
		"5",
		"6",
		"7",
		"8",
		"9",
		"10",
		"J",
		"Q",
		"K",
	];
	let shape = ["黑桃", "红桃", "梅花", "方块"];
	for (let i = 0; i < shape.length; i++) {
		for (let j = 0; j < num.length; j++) {
			let pooker = {
				name: shape[i] + num[j],
				xPos: -133 * j,
				yPos: -189 * i,
				type: i,
				points: j,
				chosen: false,
			};
			pookers.push(pooker);
		}
	}
	// let sKing = {
	// 	name: "小王",
	// 	xPos: -133 * 0,
	// 	yPos: -189 * 4,
	// 	value: 14,
	// };
	// let bKing = {
	// 	name: "大王",
	// 	xPos: -133 * 1,
	// 	yPos: -189 * 4,
	// 	value: 15,
	// };
	// pookers.push(sKing, bKing);
	export function clearCardPlayFlag() {
		for (let card of pookers) {
			card.chosen = false;
		}
	}
	export function getRndomDuck(length, upperBoundPerType) {
		let randArr = [];
		// one type can only have limit cards
		let typeCounts = [0, 0, 0, 0];
		for (let i = 0; i < length; i++) {
			let ranIdx = Math.floor(Math.random() * pookers.length);
			if (
				randArr.indexOf(pookers[ranIdx]) == -1 &&
				!pookers[ranIdx].chosen &&
				typeCounts[pookers[ranIdx].type] < upperBoundPerType
			) {
				randArr.push(pookers[ranIdx]);
				typeCounts[pookers[ranIdx].type]++;
				pookers[ranIdx].chosen = true;
			} else {
				i--;
			}
		}

		return randArr;
	}
	export function getRndomCardFromDuck(duck) {
		let ranIdx;
		do {
			ranIdx = Math.floor(Math.random() * duck.length);
		} while (duck[ranIdx].chosen);
		duck[ranIdx].chosen = true;
		return [duck[ranIdx], ranIdx];
	}
	export const bgPooker = {
		name: "背景",
		xPos: -133 * 2,
		yPos: -189 * 4,
	};
</script>

<script>
	import { createEventDispatcher } from "svelte";
	import { afterUpdate } from "svelte";
	import { spring } from "svelte/motion";
	import { pannable } from "./pannable.js";

	// pan
	const coords = spring(
		{ x: 0, y: 0 },
		{
			stiffness: 0.2,
			damping: 0.4,
		}
	);

	function handlePanStart() {
		coords.stiffness = coords.damping = 1;
		panStartHandler(wantCard, index, event.detail.dx, event.detail.dy);
	}

	function handlePanMove(event) {
		coords.update(($coords) => ({
			x: $coords.x + event.detail.dx,
			y: $coords.y + event.detail.dy,
		}));
	}

	function handlePanEnd(event) {
		coords.stiffness = 0.2;
		coords.damping = 0.4;
		let [targetX, targetY] = panEndHandler(
			wantCard,
			index,
			event.detail.x,
			event.detail.y
		);
		targetX = targetX > 0 ? targetX : 0;
		targetY = targetY > 0 ? targetY : 0;
		coords.set({ x: targetX, y: targetY });
	}
	// event
	const dispatch = createEventDispatcher();

	function play() {
		dispatch("click", {
			wantCard: wantCard,
			index: index,
		});
	}

	export let wantCard;
	export let index;
	export let vague = false;
	export let picked = false;
	export let canPan = false;
	export let panStartHandler = () => {}; // param wantCard, index  --do something when pan start
	export let panEndHandler = () => [-1, -1]; // param wantCard, index, x, y return [targetX,targetY] --handle just finished pan action

	let card;
	let cardShade;

	afterUpdate(() => {
		card.style.backgroundPosition =
			wantCard.xPos + "px " + wantCard.yPos + "px";
		card.style.left = 50 + index * 50 + "px";
		card.style["z-index"] = index * 2;
		if (cardShade) {
			cardShade.style.left = 50 + index * 50 + "px";
			cardShade.style["z-index"] = index * 2 + 1;
		}
	});
</script>

{#if canPan}
	<div
		class="pooker"
		class:picked
		class:unpicked={!picked}
		use:pannable
		on:panstart={handlePanStart}
		on:panmove={handlePanMove}
		on:panend={handlePanEnd}
		style="transform:
		translate({$coords.x}px,{$coords.y}px)"
		bind:this={card}
		on:click={play}
	>
		<slot />
	</div>
{:else}
	<div
		class="pooker"
		class:picked
		class:unpicked={!picked}
		bind:this={card}
		on:click={play}
	>
		<slot />
	</div>
{/if}

{#if vague}
	<div class="shade" bind:this={cardShade} />
{/if}

<style>
	.shade {
		position: absolute;
		width: 133px;
		height: 189px;
		z-index: 100;
		background: #a9a9a9;
		-moz-opacity: 0.7;
		opacity: 0.7;
		top: 60px;
	}

	.picked {
		top: 40px;
	}

	.unpicked {
		top: 60px;
	}

	.pooker {
		position: absolute;
		width: 133px;
		height: 189px;
		background-image: url(/images/pkr.jpg);
	}
</style>
