/** @param {import("@11ty/eleventy").UserConfig} config */
export default function (config) {
  config.addPassthroughCopy("src/assets");
  config.addPassthroughCopy({ "../.github/assets/icon.png": "assets/icon.png" });

  return {
    dir: {
      input: "src",
      output: "_site",
    },
  };
}
