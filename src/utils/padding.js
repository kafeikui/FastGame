const paddingCharactors = "!#$%&'()*+,-./:;<=>?@[]^_`{|}~";
const paddingMaxLength = 50;

export const paddingCardCodeAtRandom = (code) => {
  let original = code.toString();
  let padded = "";
  // before code
  let paddingLength = Math.floor(Math.random() * paddingMaxLength) + 1;
  for (let j = 0; j < paddingLength; j++) {
    padded +=
      paddingCharactors[Math.floor(Math.random() * paddingCharactors.length)];
  }
  // between and after code
  for (let i = 0; i < original.length; i++) {
    padded += original[i];
    let paddingLength = Math.floor(Math.random() * paddingMaxLength) + 1;
    for (let j = 0; j < paddingLength; j++) {
      padded +=
        paddingCharactors[Math.floor(Math.random() * paddingCharactors.length)];
    }
  }
  return padded;
};

export const unpaddingCardCode = (padded) => {
  let original = "";
  for (let i = 0; i < padded.length; i++) {
    if (paddingCharactors.indexOf(padded[i]) === -1) {
      original += padded[i];
    }
  }
  return Number(original);
};
