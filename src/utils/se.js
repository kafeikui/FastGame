export const SE = {
  Click: {
    path: "audios/se/click.wav",
    type: "audio/wav",
    duration: 1000,
    volume: 0.5,
  },
  Hit: {
    path: "audios/se/hit.wav",
    type: "audio/wav",
    duration: 1000,
    volume: 0.3,
  },
  Punch: {
    path: "audios/se/punch.wav",
    type: "audio/wav",
    duration: 1000,
    volume: 0.3,
  },
  Pa: {
    path: "audios/se/pa.wav",
    type: "audio/wav",
    duration: 1000,
    volume: 0.7,
  },
  Tick: {
    path: "audios/se/tick.wav",
    type: "audio/wav",
    duration: 9000,
    volume: 0.1,
  },
  Buff: {
    path: "audios/se/buff.wav",
    type: "audio/wav",
    duration: 1000,
    volume: 0.3,
  },
  Debuff: {
    path: "audios/se/debuff.mp3",
    type: "audio/mpeg",
    duration: 1000,
    volume: 0.3,
  },
};

const seList = [];
let isMuted = false;

for (let i = 0; i < 16; i++) {
  const audioElement = document.createElement("audio");
  document.body.appendChild(audioElement);
  seList.push({
    dom: audioElement,
    finishTime: 0,
  });
}

export const isPlaying = (se) => {
  const now = new Date().getTime();
  return seList.find(
    (item) => item.dom.getAttribute("src") === se.path && item.finishTime >= now
  );
};

export const stopSe = (se) => {
  seList.forEach((item) => {
    if (item.dom.getAttribute("src") === se.path) {
      item.dom.pause();
    }
  });
};

export const muteAll = () => {
  seList.forEach((item) => {
    item.dom.volume = 0;
  });
  isMuted = true;
};

export const unmuteAll = () => {
  isMuted = false;
};

export const broadcastSe = (se, needAntiShake = true) => {
  if (isMuted) {
    return;
  }
  const now = new Date().getTime();
  if (needAntiShake) {
    const sameItem = seList.find(
      (item) =>
        item.dom.getAttribute("src") === se.path &&
        Math.abs(item.finishTime - now - se.duration) < 80
    );
    if (sameItem) {
      sameItem.dom.volume = Math.min(sameItem.dom.volume + 0.1, 1);
      return;
    }
  }

  const potentialDom = seList.find((item) => item.finishTime < now);
  if (potentialDom) {
    potentialDom.dom.setAttribute("src", se.path);
    potentialDom.dom.setAttribute("type", se.type);
    potentialDom.dom.volume = se.volume;
    potentialDom.finishTime = now + se.duration;
    setTimeout(() => potentialDom.dom.play(), 0);
  } else {
    console.log("short of se", se.path);
  }
};
