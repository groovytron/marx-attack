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
import { BehaviorSubject } from 'rxjs';
import { bufferTime } from 'rxjs/operators';

ChartJS.register(CategoryScale, LinearScale, BarElement, Title, Tooltip, Legend, Colors);

interface GenreSuggestion {
  add: string|null;
  remove: string|null;
}

const EVENT = import.meta.env.VITE_EVENT_NAME;
const LOCAL_STORAGE_KEY = 'genre';
const CHART_UPDATE_DELAY = 500;
const WHITE = '#fff';
const LABELS_FONT_SIZE = 18;

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
      previousGenre: null as string|null,
      votesChanges: new BehaviorSubject<GenreSuggestion|null>(null),
      data: {
        labels: [] as string[],
        datasets: [] as any[]
      } as any,
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            display: false,
          },
        },
        scales: {
          x: {
            border: {
              color: WHITE,
            },
            ticks: {
              color: WHITE,
              font: {
                size: LABELS_FONT_SIZE,
              },
            },
          },
          y: {
            border: {
              color: WHITE,
            },
            title: {
              display: true,
              text: 'Votes',
              color: WHITE,
              font: {
                size: LABELS_FONT_SIZE,
              },
            },
            min: 0,
            ticks: {
              stepSize: 1,
              color: WHITE,
              font: {
                size: LABELS_FONT_SIZE,
              },
            }
          }
        }
      }
    };
  },
  mounted() {
    this.previousGenre = localStorage.getItem(LOCAL_STORAGE_KEY) ?? null;

    this.gun = Gun(GUN_RELAY_HOSTS);

    this.gunStats = this.gun.get(EVENT);

    this.resetStats();

    this.votesChanges.pipe(
      bufferTime(CHART_UPDATE_DELAY)
    ).subscribe(() => this.updateChartConfig());

    this.gunStats.map().on((data: GenreSuggestion|null, id: string) => {
      // Eliminate double events
      if (this.previousChanges.includes(id)) {
        return;
      }

      this.votesChanges.next(data);

      this.previousChanges.push(id);

      if (data === null) {
        this.resetStats();

        return;
      }

      if (data.add) {
        this.genreStats.set(data.add, (this.genreStats.get(data.add) ?? 0) + 1);
      }

      if (data.remove) {
        const result = this.genreStats.get(data.remove);

        if (result !== undefined && result !== 0) {
          this.genreStats.set(data.remove, result - 1);
        }
      }

      // this.updateChartConfig();
    });
  },
  methods: {
    suggestGenre(genre: string|null) {
      const previousGenre = localStorage.getItem(LOCAL_STORAGE_KEY);

      if (genre === null) {
        if (previousGenre !== null) {
          this.gunStats.set({add: null, remove: previousGenre});
        }

        localStorage.removeItem(LOCAL_STORAGE_KEY);
        this.previousGenre = genre;

        return;
      }

      this.gunStats.set({add: genre, remove: previousGenre});

      localStorage.setItem(LOCAL_STORAGE_KEY, genre);
      this.previousGenre = genre;
    },
    resetStats() {
      this.musicGenres.forEach((genreItem: string) => this.genreStats.set(genreItem, 0));
    },
    updateChartConfig() {
      this.data = {
        labels: Array.from(this.genreStats.keys()),
        datasets: [
          {
            label: 'Votes',
            data: Array.from(this.genreStats.values()),
            backgroundColor: import.meta.env.VITE_CHART_COLOR,
            color: WHITE,
          }
        ]
      };
    }
  }
})
</script>

<template>
  <div id="image-container">
    <img id="marx-picture" src="/karl_marx_laser_multiple.svg">
  </div>
  <h1 id="title">
    Marx Attack
  </h1>
  <p id="subtitle">
    L'application qui te permet d'influencer les choix des DJ's.
  </p>
  <p>
    Tu souhaites qu'un style particulier passe dans le stand ? Il te suffit de choisir le style de musique qui te fait plaisir en ce moment à l'aide des boutons en-dessous du graphe. Une fois que tu as voté le bouton correspondant sera désactivé.
  </p>
  <p>
    <b>Tu n'as le droit de voter qu'une seule fois mais tu peux changer ton vote à tout moment et faire basculer la tendance.</b>
  </p>
  <h2>Suivi des tendances en temps réel</h2>
  <div id="canvas-container">
    <Bar :data="data" :options="options" />
  </div>
  <h2>Ton vote</h2>
  <div>
    <button v-for="genreItem in musicGenres" :key="genreItem" @click="suggestGenre(genreItem)" :disabled="previousGenre === genreItem">
      {{ genreItem }}
    </button>
    <button @click="suggestGenre(null)" :disabled="previousGenre === null">
      Je m'abstiens
    </button>
  </div>
</template>

<style scoped>
  #title {
    margin-bottom: 0;
  }

  #subtitle {
    color: #caa81a;
    margin-top: 0;
  }

  #image-container, #marx-picture {
    max-width: 100%;
    height: 30vh;
  }

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
