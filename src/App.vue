<script lang="ts">
import { defineComponent } from 'vue';
import Gun, { IGunChain, IGunInstance } from 'gun';
import { MUSIC_GENRES } from './constants/music-genres';
import { GUN_RELAY_HOSTS } from './constants/gun-relay-hosts';
import {
  Chart as ChartJS,
  Colors,
  Title,
  Tooltip,
  Legend,
  BarElement,
  CategoryScale,
  LinearScale
} from 'chart.js'
import { Bar } from 'vue-chartjs'

ChartJS.register(CategoryScale, LinearScale, BarElement, Title, Tooltip, Legend, Colors);

interface GenreSuggestion {
  add: string;
  remove: string|null;
}

const EVENT = import.meta.env.VITE_EVENT_NAME;
const LOCAL_STORAGE_KEY = 'genre';

export default defineComponent({
  components: {
    Bar,
  },
  data() {
    return {
      musicGenres: MUSIC_GENRES,
      gun: {} as IGunInstance<any>,
      gunStats: {} as IGunChain<any>,
      genreStats: new Map<string, number>(),
      previousChanges: new Array<string>(),
      previousGenre: '',
      data: {
        labels: [] as string[],
        datasets: [] as any[]
      } as any,
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            display: false
          },
        },
        scales: {
          y: {
            title: {
              display: true,
              text: 'Voix',
            },
            min: 0,
            ticks: {
              stepSize: 1
            }
          }
        }
      }
    };
  },
  mounted() {
    this.previousGenre = localStorage.getItem(LOCAL_STORAGE_KEY) ?? '';

    this.gun = Gun(GUN_RELAY_HOSTS);

    this.gunStats = this.gun.get(EVENT);

    this.resetStats();

    this.gunStats.map().on((data: GenreSuggestion, id: string) => {
      // Eliminate double events
      if (this.previousChanges.includes(id)) {
        return;
      }

      this.previousChanges.push(id);

      if (data === null) {
        this.resetStats();

        return;
      }

      this.genreStats.set(data.add, (this.genreStats.get(data.add) ?? 0) + 1);

      if (data.remove) {
        const result = this.genreStats.get(data.remove);

        if (result !== undefined && result !== 0) {
          this.genreStats.set(data.remove, result - 1);
        }
      }

      this.updateChartConfig();
    });
  },
  methods: {
    suggestGenre(genre: string) {
      const previousGenre = localStorage.getItem(LOCAL_STORAGE_KEY);

      this.gunStats.set({add: genre, remove: previousGenre});

      localStorage.setItem(LOCAL_STORAGE_KEY, genre);
      this.previousGenre = genre;
    },
    resetStats() {
      this.musicGenres.forEach((genreItem: string) => this.genreStats.set(genreItem, 0));
      this.updateChartConfig();
    },
    updateChartConfig() {
      this.data = {
        labels: Array.from(this.genreStats.keys()),
        datasets: [
          {
            label: 'Votes',
            data: Array.from(this.genreStats.values()),
            backgroundColor: '#eacc2c',
            color: '#fff',
          }
        ]
      };
    }
  }
})
</script>

<template>
  <h1>Marx Attack</h1>
  <div id="canvas-container">
    <Bar :data="data" :options="options" />
  </div>
  <div>
    <button v-for="genreItem in musicGenres" :key="genreItem" @click="suggestGenre(genreItem)" :disabled="previousGenre === genreItem">
      {{ genreItem }}
    </button>
  </div>
</template>

<style scoped>
  #canvas-container {
    height: 50vh;
    width: 100%;
    margin-bottom: 2em;
  }

  button:not(:first-child) {
    margin-left: 0.5em;
  }

  button {
    margin-top: 0.25em;
  }
</style>
