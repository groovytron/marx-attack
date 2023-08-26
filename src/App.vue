<script lang="ts">
import MusicGenreSelector from './components/MusicGenreSelector.vue';
import { MUSIC_GENRES } from './constants/music-genres';

export default {
  components: {
    MusicGenreSelector
  },
  data() {
    return {
      musicGenres: MUSIC_GENRES
    }
  }
}

</script>

<template>
  <MusicGenreSelector :musicGenres="musicGenres"/>
</template>

<style scoped>
</style>
