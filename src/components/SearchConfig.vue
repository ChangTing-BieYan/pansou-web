<script setup lang="ts">
import { ref, onMounted, computed, watch } from 'vue';
import { type HealthStatus } from '@/api';

// 接收后端健康状态作为 props
const props = defineProps<{
  backendHealth: HealthStatus | null;
}>();

// 网盘类型配置
const diskTypes = [
  { id: 'baidu', name: '百度网盘', color: '#2932e1' },
  { id: 'aliyun', name: '阿里云盘', color: '#ff6a00' },
  { id: 'quark', name: '夸克网盘', color: '#1890ff' },
  { id: 'tianyi', name: '天翼云盘', color: '#0066cc' },
  { id: '115', name: '115网盘', color: '#02a7f0' },
  { id: 'xunlei', name: '迅雷网盘', color: '#0090ff' },
  { id: 'uc', name: 'UC网盘', color: '#ff6600' },
  { id: 'mobile', name: '移动云盘', color: '#0080ff' },
  { id: 'pikpak', name: 'PikPak', color: '#ff4785' },
  { id: '123', name: '123网盘', color: '#00b96b' },
  { id: 'magnet', name: '磁力链接', color: '#722ed1' },
  { id: 'ed2k', name: '电驴链接', color: '#fa8c16' }
];

// 状态数据（使用传入的 props）
const healthData = ref<HealthStatus | null>(null);
const loading = ref(true);
const error = ref<string | null>(null);

// 配置状态
const selectedChannels = ref<string[]>([]);
const selectedPlugins = ref<string[]>([]);
const selectedDiskTypes = ref<string[]>([]);
const customChannels = ref<string[]>([]);

// 新增频道输入
const newChannelInput = ref('');
const showChannelInput = ref(false);

// 保存状态提示
const saveSuccess = ref(false);
const saveTimeout = ref<number | null>(null);

// 导出模态框
const showExportModal = ref(false);

// Tab状态
const activeTab = ref<'channels' | 'plugins' | 'diskTypes'>('channels');

// 计算属性
const allChannels = computed(() => {
  if (!healthData.value) return [];
  return [...healthData.value.channels, ...customChannels.value];
});

const availablePlugins = computed(() => {
  if (!healthData.value) return [];
  return healthData.value.plugins || [];
});

// 统计信息
const stats = computed(() => ({
  channels: selectedChannels.value.length,
  plugins: selectedPlugins.value.length,
  diskTypes: selectedDiskTypes.value.length
}));

// 初始化健康状态（从 props 获取，不再调用 API）
const initHealth = () => {
  loading.value = true;
  error.value = null;
  
  if (props.backendHealth) {
    healthData.value = props.backendHealth;
    loading.value = false;
  } else {
    error.value = '获取状态失败';
    loading.value = false;
  }
};

// 监听 props 变化
watch(() => props.backendHealth, () => {
  initHealth();
}, { immediate: true });

// 加载配置
const loadConfig = () => {
  try {
    const savedChannels = localStorage.getItem('pansou_channels');
    const savedPlugins = localStorage.getItem('pansou_plugins');
    const savedDiskTypes = localStorage.getItem('pansou_disk_types');
    const savedCustomChannels = localStorage.getItem('pansou_custom_channels');

    if (savedChannels) {
      selectedChannels.value = JSON.parse(savedChannels);
    } else if (healthData.value) {
      // 默认选中所有官方频道
      selectedChannels.value = [...healthData.value.channels];
    }

    if (savedPlugins) {
      selectedPlugins.value = JSON.parse(savedPlugins);
    } else if (healthData.value) {
      // 默认选中所有插件
      selectedPlugins.value = [...healthData.value.plugins];
    }

    if (savedDiskTypes) {
      selectedDiskTypes.value = JSON.parse(savedDiskTypes);
    } else {
      // 默认选中所有网盘类型
      selectedDiskTypes.value = diskTypes.map(d => d.id);
    }

    if (savedCustomChannels) {
      customChannels.value = JSON.parse(savedCustomChannels);
    }
  } catch (err) {
    console.error('加载配置失败:', err);
  }
};

// 保存配置
const saveConfig = () => {
  try {
    localStorage.setItem('pansou_channels', JSON.stringify(selectedChannels.value));
    localStorage.setItem('pansou_plugins', JSON.stringify(selectedPlugins.value));
    localStorage.setItem('pansou_disk_types', JSON.stringify(selectedDiskTypes.value));
    localStorage.setItem('pansou_custom_channels', JSON.stringify(customChannels.value));

    // 显示保存成功提示
    saveSuccess.value = true;
    if (saveTimeout.value) {
      clearTimeout(saveTimeout.value);
    }
    saveTimeout.value = window.setTimeout(() => {
      saveSuccess.value = false;
    }, 2000);
    
    // 触发自定义事件，通知App.vue配置已更新（用于更新QQ频道按钮显示）
    window.dispatchEvent(new CustomEvent('config:saved'));
  } catch (err) {
    console.error('保存配置失败:', err);
    alert('保存配置失败，请重试');
  }
};

// 频道管理
const toggleChannel = (channel: string) => {
  const index = selectedChannels.value.indexOf(channel);
  if (index > -1) {
    selectedChannels.value.splice(index, 1);
  } else {
    selectedChannels.value.push(channel);
  }
};

const addChannel = () => {
  const channel = newChannelInput.value.trim();
  if (!channel) {
    alert('请输入频道名称');
    return;
  }
  
  if (allChannels.value.includes(channel)) {
    alert('频道已存在');
    return;
  }
  
  customChannels.value.push(channel);
  selectedChannels.value.push(channel);
  newChannelInput.value = '';
  showChannelInput.value = false;
};

const removeChannel = (channel: string) => {
  // 只能删除自定义频道
  if (!customChannels.value.includes(channel)) {
    return;
  }
  
  if (confirm(`确定要删除频道"${channel}"吗？`)) {
    const customIndex = customChannels.value.indexOf(channel);
    if (customIndex > -1) {
      customChannels.value.splice(customIndex, 1);
    }
    
    const selectedIndex = selectedChannels.value.indexOf(channel);
    if (selectedIndex > -1) {
      selectedChannels.value.splice(selectedIndex, 1);
    }
  }
};

const toggleAllChannels = () => {
  if (selectedChannels.value.length === allChannels.value.length) {
    selectedChannels.value = [];
  } else {
    selectedChannels.value = [...allChannels.value];
  }
};

// 插件管理
const togglePlugin = (plugin: string) => {
  const index = selectedPlugins.value.indexOf(plugin);
  if (index > -1) {
    selectedPlugins.value.splice(index, 1);
  } else {
    selectedPlugins.value.push(plugin);
  }
};

const toggleAllPlugins = () => {
  if (selectedPlugins.value.length === availablePlugins.value.length) {
    selectedPlugins.value = [];
  } else {
    selectedPlugins.value = [...availablePlugins.value];
  }
};

// 网盘类型管理
const toggleDiskType = (type: string) => {
  const index = selectedDiskTypes.value.indexOf(type);
  if (index > -1) {
    selectedDiskTypes.value.splice(index, 1);
  } else {
    selectedDiskTypes.value.push(type);
  }
};

const toggleAllDiskTypes = () => {
  if (selectedDiskTypes.value.length === diskTypes.length) {
    selectedDiskTypes.value = [];
  } else {
    selectedDiskTypes.value = diskTypes.map(d => d.id);
  }
};

// 重置为默认配置
const resetToDefault = () => {
  if (confirm('确定要重置为默认配置吗？这将清除所有自定义设置。')) {
    if (healthData.value) {
      selectedChannels.value = [...healthData.value.channels];
      selectedPlugins.value = [...healthData.value.plugins];
      selectedDiskTypes.value = diskTypes.map(d => d.id);
      customChannels.value = [];
      saveConfig();
    }
  }
};

// 判断是否为自定义频道
const isCustomChannel = (channel: string) => {
  return customChannels.value.includes(channel);
};

// 导出配置
const getExportData = () => {
  // 获取插件列表
  const plugins = selectedPlugins.value.join(',');
  
  // 获取TG频道列表
  const channels = selectedChannels.value.join(',');
  
  return {
    plugins,
    channels
  };
};

const openExportModal = () => {
  showExportModal.value = true;
};

const closeExportModal = () => {
  showExportModal.value = false;
};

// 复制到剪贴板的通用函数（支持降级）
const copyToClipboard = async (text: string, successMessage: string = '已复制到剪贴板！') => {
  try {
    // 尝试使用现代 Clipboard API
    if (navigator.clipboard && navigator.clipboard.writeText) {
      await navigator.clipboard.writeText(text);
      alert(successMessage);
      return true;
    }
    
    // 降级使用传统方法
    const textarea = document.createElement('textarea');
    textarea.value = text;
    textarea.style.position = 'fixed';
    textarea.style.opacity = '0';
    textarea.style.left = '-9999px';
    document.body.appendChild(textarea);
    textarea.select();
    textarea.setSelectionRange(0, text.length);
    const success = document.execCommand('copy');
    document.body.removeChild(textarea);
    
    if (success) {
      alert(successMessage);
      return true;
    } else {
      alert('复制失败，请手动复制');
      return false;
    }
  } catch (error) {
    console.error('复制失败:', error);
    alert('复制失败，请手动复制');
    return false;
  }
};

// 复制插件配置
const copyPluginsConfig = async () => {
  const data = getExportData();
  const content = data.plugins ? `export ENABLED_PLUGINS=${data.plugins}` : 'export ENABLED_PLUGINS=';
  await copyToClipboard(content, '插件配置已复制！');
};

// 复制TG频道配置
const copyChannelsConfig = async () => {
  const data = getExportData();
  const content = data.channels ? `export CHANNELS=${data.channels}` : 'export CHANNELS=';
  await copyToClipboard(content, 'TG频道配置已复制！');
};

// 组件挂载
onMounted(() => {
  initHealth();
  loadConfig();
});
</script>

<template>
  <div class="config-container">
    <!-- 头部 -->
    <div class="config-header">
      <div>
        <h1 class="config-title">搜索配置</h1>
        <p class="config-subtitle">自定义你的搜索来源和结果类型</p>
      </div>
      
      <!-- 统计信息 -->
      <div class="stats-bar">
        <div class="stat-item">
          <span class="stat-label">频道</span>
          <span class="stat-value">{{ stats.channels }}</span>
        </div>
        <div class="stat-item">
          <span class="stat-label">插件</span>
          <span class="stat-value">{{ stats.plugins }}</span>
        </div>
        <div class="stat-item">
          <span class="stat-label">网盘</span>
          <span class="stat-value">{{ stats.diskTypes }}</span>
        </div>
      </div>
    </div>

    <!-- 加载状态 -->
    <div v-if="loading" class="loading-state">
      <div class="loading-spinner"></div>
      <p>加载配置中...</p>
    </div>

    <!-- 错误状态 -->
    <div v-else-if="error" class="error-state">
      <div class="error-icon">❌</div>
      <h3>加载失败</h3>
      <p>{{ error }}</p>
      <button @click="initHealth" class="retry-btn">重试</button>
    </div>

    <!-- 配置内容 -->
    <div v-else class="config-content">
      <!-- Tab导航 -->
      <div class="tabs-nav">
        <button 
          class="tab-button" 
          :class="{ 'active': activeTab === 'channels' }"
          @click="activeTab = 'channels'"
        >
          <span class="tab-label">TG频道</span>
          <span class="tab-count">{{ allChannels.length }}</span>
        </button>
        <button 
          class="tab-button" 
          :class="{ 'active': activeTab === 'plugins' }"
          @click="activeTab = 'plugins'"
        >
          <span class="tab-label">搜索插件</span>
          <span class="tab-count">{{ availablePlugins.length }}</span>
        </button>
        <button 
          class="tab-button" 
          :class="{ 'active': activeTab === 'diskTypes' }"
          @click="activeTab = 'diskTypes'"
        >
          <span class="tab-label">网盘类型</span>
          <span class="tab-count">{{ diskTypes.length }}</span>
        </button>
      </div>

      <!-- Tab内容 -->
      <div class="tab-content">
        <!-- TG频道配置 -->
        <div v-show="activeTab === 'channels'" class="tab-pane">
          <div class="pane-header">
            <div class="pane-title">
              <h3>TG 频道配置</h3>
              <span class="selected-count">已选 {{ selectedChannels.length }} / {{ allChannels.length }}</span>
            </div>
            <div class="pane-actions">
              <button @click="toggleAllChannels" class="action-btn">
                {{ selectedChannels.length === allChannels.length ? '取消全选' : '全选' }}
              </button>
              <button @click="showChannelInput = !showChannelInput" class="action-btn primary">
                添加频道
              </button>
            </div>
          </div>

          <div class="pane-content">
          <!-- 添加频道输入框 -->
          <div v-if="showChannelInput" class="add-input-group">
            <input
              v-model="newChannelInput"
              type="text"
              placeholder="输入TG频道名称 (例如: tgsearchers3)"
              @keydown.enter="addChannel"
              class="channel-input"
            />
            <button @click="addChannel" class="confirm-btn">添加</button>
            <button @click="showChannelInput = false; newChannelInput = ''" class="cancel-btn">取消</button>
          </div>

          <!-- 频道列表 -->
          <div class="items-grid">
            <div
              v-for="channel in allChannels"
              :key="channel"
              class="item-card channel-card"
              :class="{ 
                'selected': selectedChannels.includes(channel),
                'custom': isCustomChannel(channel)
              }"
              @click="toggleChannel(channel)"
            >
              <div class="item-content">
                <div class="item-name">{{ channel }}</div>
                <div v-if="isCustomChannel(channel)" class="custom-badge">自定义</div>
              </div>
              <div class="item-actions">
                <div class="checkbox" :class="{ 'checked': selectedChannels.includes(channel) }">
                  <svg v-if="selectedChannels.includes(channel)" class="check-icon" viewBox="0 0 20 20" fill="currentColor">
                    <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd" />
                  </svg>
                </div>
                <button
                  v-if="isCustomChannel(channel)"
                  @click.stop="removeChannel(channel)"
                  class="delete-btn"
                  title="删除频道"
                >
                  ✕
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>

        <!-- 插件配置 -->
        <div v-show="activeTab === 'plugins'" class="tab-pane">
          <div class="pane-header">
            <div class="pane-title">
              <h3>搜索插件配置</h3>
              <span class="selected-count">已选 {{ selectedPlugins.length }} / {{ availablePlugins.length }}</span>
            </div>
            <div class="pane-actions">
              <button @click="toggleAllPlugins" class="action-btn">
                {{ selectedPlugins.length === availablePlugins.length ? '取消全选' : '全选' }}
              </button>
            </div>
          </div>

          <div class="pane-content">
            <div class="items-grid">
              <div
                v-for="plugin in availablePlugins"
                :key="plugin"
                class="item-card plugin-card"
                :class="{ 'selected': selectedPlugins.includes(plugin) }"
                @click="togglePlugin(plugin)"
              >
                <div class="item-content">
                  <div class="item-name">{{ plugin }}</div>
                </div>
                <div class="item-actions">
                  <div class="checkbox" :class="{ 'checked': selectedPlugins.includes(plugin) }">
                    <svg v-if="selectedPlugins.includes(plugin)" class="check-icon" viewBox="0 0 20 20" fill="currentColor">
                      <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd" />
                    </svg>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- 网盘类型配置 -->
        <div v-show="activeTab === 'diskTypes'" class="tab-pane">
          <div class="pane-header">
            <div class="pane-title">
              <h3>网盘类型配置</h3>
              <span class="selected-count">已选 {{ selectedDiskTypes.length }} / {{ diskTypes.length }}</span>
            </div>
            <div class="pane-actions">
              <button @click="toggleAllDiskTypes" class="action-btn">
                {{ selectedDiskTypes.length === diskTypes.length ? '取消全选' : '全选' }}
              </button>
            </div>
          </div>

          <div class="pane-content">
            <div class="items-grid">
              <div
                v-for="diskType in diskTypes"
                :key="diskType.id"
                class="item-card disk-card"
                :class="{ 'selected': selectedDiskTypes.includes(diskType.id) }"
                @click="toggleDiskType(diskType.id)"
              >
                <div class="item-content">
                  <div class="item-name">{{ diskType.name }}</div>
                </div>
                <div class="item-actions">
                  <div class="checkbox" :class="{ 'checked': selectedDiskTypes.includes(diskType.id) }">
                    <svg v-if="selectedDiskTypes.includes(diskType.id)" class="check-icon" viewBox="0 0 20 20" fill="currentColor">
                      <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd" />
                    </svg>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- 底部操作栏 -->
      <div class="action-bar">
        <button @click="openExportModal" class="export-btn">
          导出配置
        </button>
        <button @click="resetToDefault" class="reset-btn">
          重置默认
        </button>
        <button @click="saveConfig" class="save-btn" :class="{ 'success': saveSuccess }">
          <span v-if="saveSuccess">✓ 已保存</span>
          <span v-else>保存配置</span>
        </button>
      </div>
    </div>

    <!-- 导出模态框 -->
    <Teleport to="body">
      <Transition name="modal-fade">
        <div v-if="showExportModal" class="modal-overlay" @click="closeExportModal">
          <div class="modal-content" @click.stop>
            <div class="modal-header">
              <h2 class="modal-title">导出配置</h2>
              <button @click="closeExportModal" class="modal-close">
                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
                </svg>
              </button>
            </div>
            
            <div class="modal-body">
              <div class="export-info">
                <p>以下是您当前的配置信息，可以分别复制使用。</p>
                <a 
                  href="https://github.com/fish2018/pansou/issues/4" 
                  target="_blank" 
                  rel="noopener noreferrer"
                  class="github-link"
                >
                  📌 查看更多TG频道、QQ频道和搜索插件配置 →
                </a>
              </div>
              
              <!-- 插件配置区域 -->
              <div class="export-section">
                <div class="section-header">
                  <h3 class="section-title">
                    <span class="section-icon">🔌</span>
                    搜索插件配置
                  </h3>
                  <button @click="copyPluginsConfig" class="copy-section-btn">
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z"/>
                    </svg>
                    <span>复制</span>
                  </button>
                </div>
                <div class="export-content">
                  <pre class="export-code">{{ (() => {
                    const data = getExportData();
                    return data.plugins ? `export ENABLED_PLUGINS=${data.plugins}` : 'export ENABLED_PLUGINS=';
                  })() }}</pre>
                </div>
              </div>
              
              <!-- TG频道配置区域 -->
              <div class="export-section">
                <div class="section-header">
                  <h3 class="section-title">
                    <span class="section-icon">📡</span>
                    TG频道配置
                  </h3>
                  <button @click="copyChannelsConfig" class="copy-section-btn">
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z"/>
                    </svg>
                    <span>复制</span>
                  </button>
                </div>
                <div class="export-content">
                  <pre class="export-code">{{ (() => {
                    const data = getExportData();
                    return data.channels ? `export CHANNELS=${data.channels}` : 'export CHANNELS=';
                  })() }}</pre>
                </div>
              </div>
            </div>
            
            <div class="modal-footer">
              <button @click="closeExportModal" class="modal-close-btn-footer">
                关闭
              </button>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>
  </div>
</template>

<style scoped>
.config-container {
  max-width: 1400px;
  margin: 0 auto;
  padding: 2rem;
}

/* 头部 */
.config-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 2rem;
  padding-bottom: 1.5rem;
  border-bottom: 2px solid hsl(var(--border));
  flex-wrap: wrap;
  gap: 1.5rem;
}

.config-title {
  font-size: 1.5rem;
  font-weight: 700;
  color: hsl(var(--foreground));
  display: flex;
  align-items: center;
  gap: 0.5rem;
  margin: 0;
}

.config-subtitle {
  margin-top: 0.5rem;
  color: hsl(var(--muted-foreground));
  font-size: 0.95rem;
}

/* 统计栏 */
.stats-bar {
  display: flex;
  gap: 1.5rem;
  background: hsl(var(--muted));
  padding: 1rem 1.5rem;
  border-radius: 0.75rem;
}

.stat-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.25rem;
}

.stat-label {
  font-size: 0.75rem;
  color: hsl(var(--muted-foreground));
  font-weight: 500;
}

.stat-value {
  font-size: 1.5rem;
  font-weight: 700;
  color: hsl(var(--primary));
}

/* 加载和错误状态 */
.loading-state,
.error-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 4rem 2rem;
  text-align: center;
}

.loading-spinner {
  width: 3rem;
  height: 3rem;
  border: 4px solid hsl(var(--border));
  border-top: 4px solid hsl(var(--primary));
  border-radius: 50%;
  animation: spin 1s linear infinite;
  margin-bottom: 1rem;
}

@keyframes spin {
  to {
    transform: rotate(360deg);
  }
}

.error-icon {
  font-size: 4rem;
  margin-bottom: 1rem;
}

.retry-btn {
  margin-top: 1rem;
  padding: 0.75rem 1.5rem;
  background: hsl(var(--destructive));
  color: hsl(var(--destructive-foreground));
  border: none;
  border-radius: 0.5rem;
  cursor: pointer;
  font-weight: 500;
}

/* 配置内容 */
.config-content {
  display: flex;
  flex-direction: column;
  gap: 0;
}

/* Tab导航 */
.tabs-nav {
  display: flex;
  background: hsl(var(--muted) / 0.3);
  border: 1px solid hsl(var(--border));
  border-radius: 0.75rem 0.75rem 0 0;
  padding: 0.5rem;
  gap: 0.5rem;
}

.tab-button {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
  padding: 0.75rem 1rem;
  background: transparent;
  border: none;
  border-radius: 0.5rem;
  cursor: pointer;
  transition: all 0.2s ease;
  color: hsl(var(--muted-foreground));
  font-weight: 500;
  font-size: 0.9rem;
}

.tab-button:hover {
  background: hsl(var(--background));
  color: hsl(var(--foreground));
}

.tab-button.active {
  background: hsl(var(--background));
  color: hsl(var(--primary));
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}

.tab-label {
  white-space: nowrap;
}

.tab-count {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  min-width: 1.5rem;
  height: 1.5rem;
  padding: 0 0.4rem;
  background: hsl(var(--primary) / 0.15);
  color: hsl(var(--primary));
  border-radius: 9999px;
  font-size: 0.75rem;
  font-weight: 600;
}

.tab-button.active .tab-count {
  background: hsl(var(--primary));
  color: hsl(var(--primary-foreground));
}

/* Tab内容 */
.tab-content {
  background: hsl(var(--card));
  border: 1px solid hsl(var(--border));
  border-top: none;
  border-radius: 0 0 0.75rem 0.75rem;
  min-height: 400px;
}

.tab-pane {
  animation: fadeIn 0.3s ease;
}

@keyframes fadeIn {
  from {
    opacity: 0;
    transform: translateY(-10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

/* Pane头部 */
.pane-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1rem 1.25rem;
  border-bottom: 1px solid hsl(var(--border));
  background: hsl(var(--muted) / 0.1);
  flex-wrap: nowrap;
  gap: 1rem;
}

.pane-title {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  flex: 1;
  min-width: 0;
}

.pane-title h3 {
  font-size: 1rem;
  font-weight: 600;
  color: hsl(var(--foreground));
  margin: 0;
  white-space: nowrap;
}

.selected-count {
  font-size: 0.8rem;
  color: hsl(var(--muted-foreground));
  font-weight: 500;
  white-space: nowrap;
}

.pane-actions {
  display: flex;
  gap: 0.5rem;
  flex-shrink: 0;
}

.action-btn {
  padding: 0.4rem 0.75rem;
  background: hsl(var(--background));
  color: hsl(var(--foreground));
  border: 1px solid hsl(var(--border));
  border-radius: 0.375rem;
  font-size: 0.8rem;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s ease;
  white-space: nowrap;
}

.action-btn:hover {
  background: hsl(var(--accent));
  border-color: hsl(var(--accent));
}

.action-btn.primary {
  background: hsl(var(--primary));
  color: hsl(var(--primary-foreground));
  border-color: hsl(var(--primary));
}

.action-btn.primary:hover {
  opacity: 0.9;
}

/* Pane内容 */
.pane-content {
  padding: 1.25rem;
}

/* 添加输入框 */
.add-input-group {
  display: flex;
  gap: 0.75rem;
  margin-bottom: 1.5rem;
  padding: 1rem;
  background: hsl(var(--muted) / 0.3);
  border-radius: 0.5rem;
  flex-wrap: wrap;
}

.channel-input {
  flex: 1;
  min-width: 250px;
  padding: 0.75rem 1rem;
  border: 1px solid hsl(var(--border));
  border-radius: 0.5rem;
  background: hsl(var(--background));
  color: hsl(var(--foreground));
  font-size: 0.875rem;
  outline: none;
}

.channel-input:focus {
  border-color: hsl(var(--primary));
  box-shadow: 0 0 0 3px hsl(var(--primary) / 0.1);
}

.confirm-btn,
.cancel-btn {
  padding: 0.75rem 1.25rem;
  border: none;
  border-radius: 0.5rem;
  font-size: 0.875rem;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s ease;
}

.confirm-btn {
  background: hsl(var(--primary));
  color: hsl(var(--primary-foreground));
}

.confirm-btn:hover {
  opacity: 0.9;
}

.cancel-btn {
  background: hsl(var(--muted));
  color: hsl(var(--muted-foreground));
}

.cancel-btn:hover {
  background: hsl(var(--accent));
}

/* 项目网格 */
.items-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(140px, 1fr));
  gap: 0.5rem;
  max-height: 400px;
  overflow-y: auto;
  padding: 0.25rem;
}

.items-grid::-webkit-scrollbar {
  width: 8px;
}

.items-grid::-webkit-scrollbar-track {
  background: hsl(var(--muted));
  border-radius: 4px;
}

.items-grid::-webkit-scrollbar-thumb {
  background: hsl(var(--muted-foreground) / 0.3);
  border-radius: 4px;
}

.items-grid::-webkit-scrollbar-thumb:hover {
  background: hsl(var(--muted-foreground) / 0.5);
}

/* 项目卡片 */
.item-card {
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  padding: 0.5rem 0.75rem;
  background: hsl(var(--background));
  border: 1px solid hsl(var(--border));
  border-radius: 0.5rem;
  cursor: pointer;
  transition: all 0.2s ease;
  position: relative;
  min-height: 60px;
}

.item-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
  border-color: hsl(var(--primary) / 0.5);
}

.item-card.selected {
  background: hsl(var(--primary) / 0.1);
  border-color: hsl(var(--primary));
}

.item-content {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.25rem;
  margin-bottom: 0.5rem;
}

.item-name {
  font-size: 0.8rem;
  font-weight: 500;
  color: hsl(var(--foreground));
  text-align: center;
  word-break: break-word;
}

.custom-badge {
  font-size: 0.7rem;
  padding: 0.15rem 0.5rem;
  background: hsl(var(--accent));
  color: hsl(var(--accent-foreground));
  border-radius: 9999px;
  font-weight: 600;
}

.item-actions {
  display: flex;
  justify-content: center;
  align-items: center;
  gap: 0.5rem;
}

/* 复选框 */
.checkbox {
  width: 18px;
  height: 18px;
  border: 2px solid hsl(var(--border));
  border-radius: 0.25rem;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s ease;
}

.checkbox.checked {
  background: hsl(var(--primary));
  border-color: hsl(var(--primary));
}

.check-icon {
  width: 12px;
  height: 12px;
  color: hsl(var(--primary-foreground));
}

/* 删除按钮 */
.delete-btn {
  padding: 0.1rem 0.3rem;
  background: transparent;
  border: none;
  cursor: pointer;
  font-size: 0.9rem;
  opacity: 0.5;
  transition: all 0.2s ease;
  color: hsl(var(--destructive));
}

.delete-btn:hover {
  opacity: 1;
  background: hsl(var(--destructive) / 0.1);
  border-radius: 0.25rem;
}

/* 底部操作栏 */
.action-bar {
  display: flex;
  justify-content: center;
  gap: 1rem;
  padding: 2rem 0;
  margin-top: 1rem;
  border-top: 2px solid hsl(var(--border));
}

.reset-btn,
.export-btn,
.save-btn {
  padding: 0.75rem 1.5rem;
  border: none;
  border-radius: 0.5rem;
  font-size: 0.875rem;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s ease;
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.reset-btn {
  background: hsl(var(--muted));
  color: hsl(var(--muted-foreground));
}

.reset-btn:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px hsl(var(--primary) / 0.4);
}

.export-btn {
  background: hsl(var(--primary));
  color: hsl(var(--primary-foreground));
  border: 1px solid hsl(var(--border));
}

.export-btn:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px hsl(var(--primary) / 0.4);
}

.save-btn {
  background: hsl(var(--primary));
  color: hsl(var(--primary-foreground));
  box-shadow: 0 2px 8px hsl(var(--primary) / 0.3);
}

.save-btn:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px hsl(var(--primary) / 0.4);
}

.save-btn.success {
  background: #10b981;
}

/* 模态框样式 */
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.6);
  backdrop-filter: blur(4px);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
  padding: 1rem;
}

.modal-content {
  background: hsl(var(--background));
  border: 1px solid hsl(var(--border));
  border-radius: 1rem;
  max-width: 800px;
  width: 100%;
  max-height: 90vh;
  display: flex;
  flex-direction: column;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
  animation: modalSlideUp 0.3s ease-out;
}

@keyframes modalSlideUp {
  from {
    opacity: 0;
    transform: translateY(20px) scale(0.95);
  }
  to {
    opacity: 1;
    transform: translateY(0) scale(1);
  }
}

.modal-header {
  padding: 1.5rem;
  border-bottom: 1px solid hsl(var(--border));
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.modal-title {
  font-size: 1.5rem;
  font-weight: 700;
  color: hsl(var(--foreground));
  margin: 0;
}

.modal-close {
  padding: 0.5rem;
  background: transparent;
  border: none;
  color: hsl(var(--muted-foreground));
  cursor: pointer;
  border-radius: 0.375rem;
  transition: all 0.2s ease;
}

.modal-close:hover {
  background: hsl(var(--accent));
  color: hsl(var(--accent-foreground));
}

.modal-body {
  padding: 1.5rem;
  overflow-y: auto;
  flex: 1;
}

.export-info {
  margin-bottom: 1.5rem;
}

.export-info p {
  color: hsl(var(--muted-foreground));
  margin-bottom: 1rem;
  font-size: 0.95rem;
}

.github-link {
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
  color: hsl(var(--primary));
  text-decoration: none;
  font-weight: 500;
  font-size: 0.95rem;
  padding: 0.5rem 1rem;
  background: hsl(var(--primary) / 0.1);
  border-radius: 0.5rem;
  transition: all 0.2s ease;
}

.github-link:hover {
  background: hsl(var(--primary) / 0.2);
  transform: translateX(4px);
}

/* 配置区域 */
.export-section {
  margin-bottom: 1.5rem;
  border: 1px solid hsl(var(--border));
  border-radius: 0.75rem;
  overflow: hidden;
  transition: all 0.2s ease;
}

.export-section:hover {
  border-color: hsl(var(--primary) / 0.3);
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.05);
}

.export-section:last-child {
  margin-bottom: 0;
}

.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1rem 1.25rem;
  background: hsl(var(--muted) / 0.3);
  border-bottom: 1px solid hsl(var(--border));
}

.section-title {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  margin: 0;
  font-size: 1rem;
  font-weight: 600;
  color: hsl(var(--foreground));
}

.section-icon {
  font-size: 1.25rem;
}

.copy-section-btn {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.5rem 1rem;
  background: hsl(var(--primary));
  color: hsl(var(--primary-foreground));
  border: none;
  border-radius: 0.375rem;
  font-size: 0.875rem;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s ease;
}

.copy-section-btn:hover {
  background: hsl(var(--primary) / 0.9);
  transform: translateY(-1px);
  box-shadow: 0 2px 8px hsl(var(--primary) / 0.3);
}

.copy-section-btn:active {
  transform: translateY(0);
}

.export-content {
  background: hsl(var(--background));
  padding: 1rem;
}

.export-code {
  margin: 0;
  font-family: ui-monospace, 'Cascadia Code', 'Source Code Pro', Menlo, Consolas, 'DejaVu Sans Mono', monospace;
  font-size: 0.875rem;
  line-height: 1.6;
  color: hsl(var(--foreground));
  white-space: pre-wrap;
  word-wrap: break-word;
}

.modal-footer {
  padding: 1.5rem;
  border-top: 1px solid hsl(var(--border));
  display: flex;
  justify-content: center;
  gap: 1rem;
}

.modal-close-btn-footer {
  padding: 0.75rem 2rem;
  background: hsl(var(--muted));
  color: hsl(var(--muted-foreground));
  border: none;
  border-radius: 0.5rem;
  font-size: 0.875rem;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s ease;
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.modal-close-btn-footer:hover {
  background: hsl(var(--accent));
  color: hsl(var(--accent-foreground));
}

/* 模态框过渡动画 */
.modal-fade-enter-active,
.modal-fade-leave-active {
  transition: opacity 0.3s ease;
}

.modal-fade-enter-from,
.modal-fade-leave-to {
  opacity: 0;
}

.modal-fade-enter-active .modal-content,
.modal-fade-leave-active .modal-content {
  transition: transform 0.3s ease, opacity 0.3s ease;
}

.modal-fade-enter-from .modal-content,
.modal-fade-leave-to .modal-content {
  transform: translateY(20px) scale(0.95);
  opacity: 0;
}

/* 响应式设计 */
@media (max-width: 768px) {
  .config-container {
    padding: 1rem;
  }

  .config-header {
    flex-direction: column;
    align-items: stretch;
  }

  .stats-bar {
    justify-content: space-around;
  }

  .config-title {
    font-size: 1.25rem;
  }

  .tabs-nav {
    flex-direction: row;
    overflow-x: auto;
  }

  .tab-button {
    flex: 0 0 auto;
    min-width: 100px;
    font-size: 0.85rem;
    padding: 0.6rem 0.75rem;
  }

  .tab-label {
    font-size: 0.8rem;
  }

  .tab-count {
    font-size: 0.7rem;
    min-width: 1.25rem;
    height: 1.25rem;
  }

  .pane-header {
    flex-direction: column;
    align-items: stretch;
    gap: 0.75rem;
  }

  .pane-title {
    flex-direction: column;
    align-items: flex-start;
    gap: 0.25rem;
  }

  .pane-actions {
    width: 100%;
    justify-content: stretch;
  }

  .action-btn {
    flex: 1;
    padding: 0.5rem;
    font-size: 0.75rem;
  }

  .items-grid {
    grid-template-columns: repeat(auto-fill, minmax(110px, 1fr));
    max-height: 300px;
  }

  .add-input-group {
    flex-direction: column;
  }

  .channel-input {
    width: 100%;
    min-width: auto;
  }

  .action-bar {
    flex-direction: column;
  }

  .reset-btn,
  .export-btn,
  .save-btn {
    width: 100%;
    justify-content: center;
  }

  .modal-content {
    max-height: 95vh;
    margin: 0.5rem;
  }

  .modal-header {
    padding: 1rem;
  }

  .modal-title {
    font-size: 1.25rem;
  }

  .modal-body {
    padding: 1rem;
  }

  .modal-footer {
    padding: 1rem;
  }

  .modal-close-btn-footer {
    width: 100%;
    justify-content: center;
  }

  .section-header {
    flex-direction: column;
    gap: 0.75rem;
    align-items: stretch;
  }

  .copy-section-btn {
    width: 100%;
    justify-content: center;
  }

  .export-code {
    font-size: 0.75rem;
  }
}
</style>

